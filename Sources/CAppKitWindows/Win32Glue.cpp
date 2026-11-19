#ifdef _WIN32
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <shlwapi.h>
#include <dwmapi.h>
#include <commctrl.h>
#include <imm.h>
#include <bcrypt.h>
#include <objidl.h>
#include <gdiplus.h>
#pragma comment(lib, "comctl32.lib")

#include "CAppKitWindows.h"

#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <string>
#include <vector>

namespace {

std::wstring ToWide(const char *utf8) {
  if (!utf8 || !*utf8) return L"";
  int needed = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, nullptr, 0);
  if (needed <= 1) return L"";
  std::wstring out(needed - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8, -1, out.data(), needed);
  return out;
}

std::string ToUtf8(const std::wstring &wide) {
  if (wide.empty()) return "";
  int needed = WideCharToMultiByte(CP_UTF8, 0, wide.data(), (int)wide.size(), nullptr, 0, nullptr, nullptr);
  if (needed <= 0) return "";
  std::string out(needed, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), (int)wide.size(), out.data(), needed, nullptr, nullptr);
  return out;
}

char *DupString(const std::string &s) {
  char *buf = (char *)std::malloc(s.size() + 1);
  if (!buf) return nullptr;
  std::memcpy(buf, s.data(), s.size());
  buf[s.size()] = '\0';
  return buf;
}

void CopyToBuf(const std::string &s, char *buf, int cap) {
  if (!buf || cap <= 0) return;
  size_t n = std::min((size_t)(cap - 1), s.size());
  std::memcpy(buf, s.data(), n);
  buf[n] = '\0';
}

void EnsureGdiPlus() {
  static ULONG_PTR token = 0;
  static bool initialized = false;
  if (!initialized) {
    Gdiplus::GdiplusStartupInput input;
    if (Gdiplus::GdiplusStartup(&token, &input, nullptr) == Gdiplus::Ok) {
      initialized = true;
    }
  }
}

bool GetPngClsid(CLSID *out_clsid) {
  EnsureGdiPlus();
  UINT num = 0, size = 0;
  Gdiplus::GetImageEncodersSize(&num, &size);
  if (size == 0) return false;
  std::vector<uint8_t> buf(size);
  auto *info = reinterpret_cast<Gdiplus::ImageCodecInfo *>(buf.data());
  Gdiplus::GetImageEncoders(num, size, info);
  for (UINT i = 0; i < num; ++i) {
    if (std::wcscmp(info[i].MimeType, L"image/png") == 0) {
      *out_clsid = info[i].Clsid;
      return true;
    }
  }
  return false;
}

uint8_t *EncodeBitmapToPng(Gdiplus::Bitmap *bmp, size_t *out_len) {
  if (!bmp || bmp->GetLastStatus() != Gdiplus::Ok) return nullptr;
  CLSID png_clsid;
  if (!GetPngClsid(&png_clsid)) return nullptr;
  IStream *stream = nullptr;
  if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream)) || !stream) return nullptr;
  uint8_t *result = nullptr;
  if (bmp->Save(stream, &png_clsid, nullptr) == Gdiplus::Ok) {
    HGLOBAL hg = nullptr;
    if (SUCCEEDED(GetHGlobalFromStream(stream, &hg)) && hg) {
      SIZE_T sz = GlobalSize(hg);
      void *ptr = GlobalLock(hg);
      if (ptr && sz > 0) {
        result = (uint8_t *)std::malloc(sz);
        if (result) {
          std::memcpy(result, ptr, sz);
          if (out_len) *out_len = sz;
        }
        GlobalUnlock(hg);
      }
    }
  }
  stream->Release();
  return result;
}

Gdiplus::Bitmap *DecodeBitmapFromMemory(const uint8_t *data, size_t len) {
  if (!data || len == 0) return nullptr;
  EnsureGdiPlus();
  HGLOBAL hg = GlobalAlloc(GMEM_MOVEABLE, len);
  if (!hg) return nullptr;
  void *ptr = GlobalLock(hg);
  if (!ptr) {
    GlobalFree(hg);
    return nullptr;
  }
  std::memcpy(ptr, data, len);
  GlobalUnlock(hg);
  IStream *stream = nullptr;
  if (FAILED(CreateStreamOnHGlobal(hg, TRUE, &stream)) || !stream) {
    GlobalFree(hg);
    return nullptr;
  }
  auto *bmp = Gdiplus::Bitmap::FromStream(stream);
  stream->Release();
  if (!bmp || bmp->GetLastStatus() != Gdiplus::Ok) {
    delete bmp;
    return nullptr;
  }
  return bmp;
}

Gdiplus::Bitmap *BitmapFromHIconWithAlpha(HICON hicon) {
  if (!hicon) return nullptr;
  EnsureGdiPlus();
  ICONINFO ii{};
  if (!GetIconInfo(hicon, &ii)) return nullptr;
  BITMAP bm{};
  Gdiplus::Bitmap *result = nullptr;
  if (ii.hbmColor && GetObjectW(ii.hbmColor, sizeof(bm), &bm) && bm.bmBitsPixel == 32) {
    BITMAPINFO bmi{};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = bm.bmWidth;
    bmi.bmiHeader.biHeight = -bm.bmHeight; // top-down
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    std::vector<uint8_t> pixels((size_t)bm.bmWidth * (size_t)bm.bmHeight * 4);
    HDC hdc = GetDC(nullptr);
    if (GetDIBits(hdc, ii.hbmColor, 0, bm.bmHeight, pixels.data(), &bmi, DIB_RGB_COLORS)) {
      result = new Gdiplus::Bitmap(bm.bmWidth, bm.bmHeight, PixelFormat32bppARGB);
      Gdiplus::BitmapData bd{};
      Gdiplus::Rect rect(0, 0, bm.bmWidth, bm.bmHeight);
      if (result->LockBits(&rect, Gdiplus::ImageLockModeWrite, PixelFormat32bppARGB, &bd) == Gdiplus::Ok) {
        for (int y = 0; y < bm.bmHeight; ++y) {
          std::memcpy(
              static_cast<uint8_t *>(bd.Scan0) + y * bd.Stride,
              pixels.data() + (size_t)y * bm.bmWidth * 4,
              (size_t)bm.bmWidth * 4);
        }
        result->UnlockBits(&bd);
      }
    }
    ReleaseDC(nullptr, hdc);
  }
  if (!result) {
    result = Gdiplus::Bitmap::FromHICON(hicon);
  }
  if (ii.hbmColor) DeleteObject(ii.hbmColor);
  if (ii.hbmMask) DeleteObject(ii.hbmMask);
  return result;
}

bool IsRealAppWindow(HWND hwnd) {
  if (!IsWindowVisible(hwnd)) return false;
  LONG_PTR ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  if (ex & WS_EX_TOOLWINDOW) return false;
  HWND owner = GetWindow(hwnd, GW_OWNER);
  if (owner != nullptr && !(ex & WS_EX_APPWINDOW)) return false;
  INT cloaked = 0;
  if (SUCCEEDED(DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked, sizeof(cloaked))) && cloaked != 0) {
    return false;
  }
  wchar_t cls[64] = {};
  GetClassNameW(hwnd, cls, 63);
  if (std::wcscmp(cls, L"Progman") == 0 || std::wcscmp(cls, L"WorkerW") == 0 ||
      std::wcscmp(cls, L"Shell_TrayWnd") == 0 || std::wcscmp(cls, L"Shell_SecondaryTrayWnd") == 0) {
    return false;
  }
  return true;
}

int HashBCrypt(LPCWSTR alg_id, const uint8_t *key, size_t key_len, const uint8_t *data, size_t data_len, uint8_t *out, size_t out_len) {
  BCRYPT_ALG_HANDLE hAlg = nullptr;
  ULONG flags = key ? BCRYPT_ALG_HANDLE_HMAC_FLAG : 0;
  if (BCryptOpenAlgorithmProvider(&hAlg, alg_id, nullptr, flags) != 0) return 0;
  NTSTATUS st = BCryptHash(
      hAlg,
      const_cast<PUCHAR>(key), (ULONG)key_len,
      const_cast<PUCHAR>(data), (ULONG)data_len,
      out, (ULONG)out_len);
  BCryptCloseAlgorithmProvider(hAlg, 0);
  return st == 0 ? 1 : 0;
}

} // namespace

extern "C" {

void cak_free(void *ptr) {
  std::free(ptr);
}

uint32_t cak_clipboard_sequence_number(void) {
  return (uint32_t)GetClipboardSequenceNumber();
}

int cak_clipboard_clear(void) {
  if (!OpenClipboard(nullptr)) return 0;
  BOOL ok = EmptyClipboard();
  CloseClipboard();
  return ok ? 1 : 0;
}

char *cak_clipboard_get_text(void) {
  if (!IsClipboardFormatAvailable(CF_UNICODETEXT)) return nullptr;
  if (!OpenClipboard(nullptr)) return nullptr;
  char *result = nullptr;
  HANDLE hData = GetClipboardData(CF_UNICODETEXT);
  if (hData) {
    const wchar_t *wstr = static_cast<const wchar_t *>(GlobalLock(hData));
    if (wstr) {
      result = DupString(ToUtf8(wstr));
      GlobalUnlock(hData);
    }
  }
  CloseClipboard();
  return result;
}

int cak_clipboard_set_text(const char *utf8_text) {
  if (!utf8_text) return 0;
  std::wstring wide = ToWide(utf8_text);
  if (!OpenClipboard(nullptr)) return 0;
  EmptyClipboard();
  size_t bytes = (wide.size() + 1) * sizeof(wchar_t);
  HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, bytes);
  int ok = 0;
  if (hMem) {
    void *ptr = GlobalLock(hMem);
    if (ptr) {
      std::memcpy(ptr, wide.c_str(), bytes);
      GlobalUnlock(hMem);
      if (SetClipboardData(CF_UNICODETEXT, hMem)) {
        ok = 1;
      } else {
        GlobalFree(hMem);
      }
    } else {
      GlobalFree(hMem);
    }
  }
  CloseClipboard();
  return ok;
}

char *cak_clipboard_get_files_newline(void) {
  if (!IsClipboardFormatAvailable(CF_HDROP)) return nullptr;
  if (!OpenClipboard(nullptr)) return nullptr;
  std::string joined;
  HDROP hDrop = static_cast<HDROP>(GetClipboardData(CF_HDROP));
  if (hDrop) {
    UINT count = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
    for (UINT i = 0; i < count; ++i) {
      UINT len = DragQueryFileW(hDrop, i, nullptr, 0);
      if (len > 0) {
        std::wstring path(len + 1, L'\0');
        DragQueryFileW(hDrop, i, path.data(), len + 1);
        path.resize(len);
        if (!joined.empty()) joined.push_back('\n');
        joined += ToUtf8(path);
      }
    }
  }
  CloseClipboard();
  return joined.empty() ? nullptr : DupString(joined);
}

int cak_clipboard_set_files(const char *const *utf8_paths, int count) {
  if (!utf8_paths || count <= 0) return 0;
  std::vector<wchar_t> multi;
  for (int i = 0; i < count; ++i) {
    std::wstring w = ToWide(utf8_paths[i]);
    if (w.empty()) continue;
    multi.insert(multi.end(), w.begin(), w.end());
    multi.push_back(L'\0');
  }
  multi.push_back(L'\0');
  size_t total = sizeof(DROPFILES) + multi.size() * sizeof(wchar_t);
  if (!OpenClipboard(nullptr)) return 0;
  EmptyClipboard();
  HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, total);
  int ok = 0;
  if (hMem) {
    auto *df = static_cast<DROPFILES *>(GlobalLock(hMem));
    if (df) {
      df->pFiles = sizeof(DROPFILES);
      df->fWide = TRUE;
      std::memcpy(reinterpret_cast<uint8_t *>(df) + sizeof(DROPFILES), multi.data(), multi.size() * sizeof(wchar_t));
      GlobalUnlock(hMem);
      if (SetClipboardData(CF_HDROP, hMem)) ok = 1;
      else GlobalFree(hMem);
    } else {
      GlobalFree(hMem);
    }
  }
  CloseClipboard();
  return ok;
}

uint8_t *cak_clipboard_get_png(size_t *out_len) {
  if (out_len) *out_len = 0;
  UINT png_fmt = RegisterClipboardFormatW(L"PNG");
  if (!IsClipboardFormatAvailable(png_fmt) && !IsClipboardFormatAvailable(CF_BITMAP)) return nullptr;
  if (!OpenClipboard(nullptr)) return nullptr;
  uint8_t *result = nullptr;
  if (IsClipboardFormatAvailable(png_fmt)) {
    HANDLE hData = GetClipboardData(png_fmt);
    if (hData) {
      SIZE_T sz = GlobalSize(hData);
      const void *ptr = GlobalLock(hData);
      if (ptr && sz > 0) {
        result = (uint8_t *)std::malloc(sz);
        if (result) {
          std::memcpy(result, ptr, sz);
          if (out_len) *out_len = sz;
        }
        GlobalUnlock(hData);
      }
    }
  }
  if (!result && IsClipboardFormatAvailable(CF_BITMAP)) {
    EnsureGdiPlus();
    HBITMAP hBmp = static_cast<HBITMAP>(GetClipboardData(CF_BITMAP));
    if (hBmp) {
      Gdiplus::Bitmap *bmp = Gdiplus::Bitmap::FromHBITMAP(hBmp, nullptr);
      result = EncodeBitmapToPng(bmp, out_len);
      delete bmp;
    }
  }
  CloseClipboard();
  return result;
}

int cak_clipboard_set_png(const uint8_t *png_data, size_t len) {
  Gdiplus::Bitmap *bmp = DecodeBitmapFromMemory(png_data, len);
  if (!bmp) return 0;
  if (!OpenClipboard(nullptr)) {
    delete bmp;
    return 0;
  }
  EmptyClipboard();
  int ok = 0;
  UINT png_fmt = RegisterClipboardFormatW(L"PNG");
  HGLOBAL hPng = GlobalAlloc(GMEM_MOVEABLE, len);
  if (hPng) {
    void *ptr = GlobalLock(hPng);
    if (ptr) {
      std::memcpy(ptr, png_data, len);
      GlobalUnlock(hPng);
      if (SetClipboardData(png_fmt, hPng)) ok = 1;
      else GlobalFree(hPng);
    } else {
      GlobalFree(hPng);
    }
  }
  HBITMAP hBitmap = nullptr;
  if (bmp->GetHBITMAP(Gdiplus::Color(0, 0, 0, 0), &hBitmap) == Gdiplus::Ok && hBitmap) {
    if (SetClipboardData(CF_BITMAP, hBitmap)) ok = 1;
    else DeleteObject(hBitmap);
  }
  CloseClipboard();
  delete bmp;
  return ok;
}

int cak_open_url_or_path(const char *utf8_target) {
  std::wstring w = ToWide(utf8_target);
  if (w.empty()) return 0;
  HINSTANCE res = ShellExecuteW(nullptr, L"open", w.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
  return reinterpret_cast<INT_PTR>(res) > 32 ? 1 : 0;
}

int cak_open_with_app(const char *utf8_app, const char *utf8_arg) {
  std::wstring app = ToWide(utf8_app);
  if (app.empty()) return 0;
  std::wstring arg = ToWide(utf8_arg);
  if (!arg.empty()) arg = L"\"" + arg + L"\"";
  HINSTANCE res = ShellExecuteW(nullptr, L"open", app.c_str(), arg.empty() ? nullptr : arg.c_str(), nullptr, SW_SHOWNORMAL);
  return reinterpret_cast<INT_PTR>(res) > 32 ? 1 : 0;
}

int cak_reveal_in_explorer(const char *utf8_path) {
  std::wstring w = ToWide(utf8_path);
  if (w.empty()) return 0;
  for (auto &ch : w) {
    if (ch == L'/') ch = L'\\';
  }
  PIDLIST_ABSOLUTE pidl = ILCreateFromPathW(w.c_str());
  if (!pidl) return 0;
  HRESULT hr = SHOpenFolderAndSelectItems(pidl, 0, nullptr, 0);
  ILFree(pidl);
  return SUCCEEDED(hr) ? 1 : 0;
}

uint32_t cak_frontmost_pid(void) {
  HWND fg = GetForegroundWindow();
  if (!fg) return 0;
  DWORD pid = 0;
  GetWindowThreadProcessId(fg, &pid);
  return (uint32_t)pid;
}

uint32_t cak_current_pid(void) {
  return (uint32_t)GetCurrentProcessId();
}

int cak_process_info(uint32_t pid, char *exe_buf, int exe_cap, char *title_buf, int title_cap) {
  if (exe_buf && exe_cap > 0) exe_buf[0] = '\0';
  if (title_buf && title_cap > 0) title_buf[0] = '\0';
  if (pid == 0) return 0;
  HANDLE hProc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (!hProc) return 0;
  wchar_t path[MAX_PATH * 2] = {};
  DWORD sz = MAX_PATH * 2;
  bool ok = QueryFullProcessImageNameW(hProc, 0, path, &sz) != FALSE;
  CloseHandle(hProc);
  if (!ok) return 0;
  CopyToBuf(ToUtf8(path), exe_buf, exe_cap);

  struct TitleCtx {
    DWORD pid;
    std::wstring title;
  } ctx{pid, L""};
  EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
    auto *c = reinterpret_cast<TitleCtx *>(lp);
    DWORD wpid = 0;
    GetWindowThreadProcessId(hwnd, &wpid);
    if (wpid != c->pid || !IsRealAppWindow(hwnd)) return TRUE;
    int len = GetWindowTextLengthW(hwnd);
    if (len > 0) {
      c->title.resize(len + 1);
      GetWindowTextW(hwnd, c->title.data(), len + 1);
      c->title.resize(len);
      return FALSE;
    }
    return TRUE;
  }, reinterpret_cast<LPARAM>(&ctx));
  CopyToBuf(ToUtf8(ctx.title), title_buf, title_cap);
  return 1;
}

int cak_activate_pid(uint32_t pid) {
  if (pid == 0) return 0;
  HWND target = nullptr;
  struct FindCtx {
    DWORD pid;
    HWND found;
  } ctx{pid, nullptr};
  EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
    auto *c = reinterpret_cast<FindCtx *>(lp);
    DWORD wpid = 0;
    GetWindowThreadProcessId(hwnd, &wpid);
    if (wpid == c->pid && IsRealAppWindow(hwnd)) {
      c->found = hwnd;
      return FALSE;
    }
    return TRUE;
  }, reinterpret_cast<LPARAM>(&ctx));
  target = ctx.found;
  if (!target) return 0;
  if (IsIconic(target)) ShowWindow(target, SW_RESTORE);
  HWND fg = GetForegroundWindow();
  DWORD fgThread = fg ? GetWindowThreadProcessId(fg, nullptr) : 0;
  DWORD curThread = GetCurrentThreadId();
  if (fgThread && fgThread != curThread) AttachThreadInput(curThread, fgThread, TRUE);
  BringWindowToTop(target);
  BOOL ok = SetForegroundWindow(target);
  if (fgThread && fgThread != curThread) AttachThreadInput(curThread, fgThread, FALSE);
  return ok ? 1 : 0;
}

int cak_hide_pid(uint32_t pid) {
  if (pid == 0) return 0;
  struct HideCtx {
    DWORD pid;
    int count;
  } ctx{pid, 0};
  EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
    auto *c = reinterpret_cast<HideCtx *>(lp);
    DWORD wpid = 0;
    GetWindowThreadProcessId(hwnd, &wpid);
    if (wpid == c->pid && IsRealAppWindow(hwnd)) {
      ShowWindow(hwnd, SW_MINIMIZE);
      c->count++;
    }
    return TRUE;
  }, reinterpret_cast<LPARAM>(&ctx));
  return ctx.count > 0 ? 1 : 0;
}

int cak_terminate_pid(uint32_t pid, int force) {
  if (pid == 0) return 0;
  if (!force) {
    struct CloseCtx {
      DWORD pid;
      int sent;
    } ctx{pid, 0};
    EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
      auto *c = reinterpret_cast<CloseCtx *>(lp);
      DWORD wpid = 0;
      GetWindowThreadProcessId(hwnd, &wpid);
      if (wpid == c->pid && IsWindowVisible(hwnd)) {
        PostMessageW(hwnd, WM_CLOSE, 0, 0);
        c->sent++;
      }
      return TRUE;
    }, reinterpret_cast<LPARAM>(&ctx));
    if (ctx.sent > 0) return 1;
  }
  HANDLE hProc = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
  if (!hProc) return 0;
  BOOL ok = TerminateProcess(hProc, 0);
  CloseHandle(hProc);
  return ok ? 1 : 0;
}

uint32_t *cak_enum_gui_pids(int *out_count) {
  if (out_count) *out_count = 0;
  std::vector<uint32_t> pids;
  EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
    if (!IsRealAppWindow(hwnd)) return TRUE;
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != 0) {
      auto *vec = reinterpret_cast<std::vector<uint32_t> *>(lp);
      if (std::find(vec->begin(), vec->end(), (uint32_t)pid) == vec->end()) {
        vec->push_back((uint32_t)pid);
      }
    }
    return TRUE;
  }, reinterpret_cast<LPARAM>(&pids));
  if (pids.empty()) return nullptr;
  auto *arr = (uint32_t *)std::malloc(pids.size() * sizeof(uint32_t));
  if (!arr) return nullptr;
  std::memcpy(arr, pids.data(), pids.size() * sizeof(uint32_t));
  if (out_count) *out_count = (int)pids.size();
  return arr;
}

uint8_t *cak_file_icon_png(const char *utf8_path, int size_px, size_t *out_len) {
  if (out_len) *out_len = 0;
  std::wstring w = ToWide(utf8_path);
  if (w.empty()) return nullptr;
  for (auto &ch : w) {
    if (ch == L'/') ch = L'\\';
  }
  if (w.size() >= 3 && w[0] == L'\\' && iswalpha(w[1]) && w[2] == L':') {
    w.erase(0, 1);
  }
  HRESULT hrInit = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  SHFILEINFOW sfi{};
  DWORD attrs = FILE_ATTRIBUTE_NORMAL;
  UINT flags = SHGFI_ICON | (size_px > 20 ? SHGFI_LARGEICON : SHGFI_SMALLICON);
  if (GetFileAttributesW(w.c_str()) == INVALID_FILE_ATTRIBUTES) {
    flags |= SHGFI_USEFILEATTRIBUTES;
  }
  DWORD_PTR ok = SHGetFileInfoW(w.c_str(), attrs, &sfi, sizeof(sfi), flags);
  if (!ok || !sfi.hIcon) {
    if (SUCCEEDED(hrInit)) CoUninitialize();
    return nullptr;
  }
  EnsureGdiPlus();
  Gdiplus::Bitmap *bmp = BitmapFromHIconWithAlpha(sfi.hIcon);
  DestroyIcon(sfi.hIcon);
  uint8_t *png = EncodeBitmapToPng(bmp, out_len);
  delete bmp;
  if (SUCCEEDED(hrInit)) CoUninitialize();
  return png;
}

int cak_resolve_lnk(
    const char *utf8_lnk_path,
    char *target_buf, int target_cap,
    char *args_buf, int args_cap,
    char *icon_buf, int icon_cap,
    int *out_icon_index,
    char *desc_buf, int desc_cap
) {
  if (target_buf && target_cap > 0) target_buf[0] = '\0';
  if (args_buf && args_cap > 0) args_buf[0] = '\0';
  if (icon_buf && icon_cap > 0) icon_buf[0] = '\0';
  if (desc_buf && desc_cap > 0) desc_buf[0] = '\0';
  if (out_icon_index) *out_icon_index = 0;

  std::wstring wpath = ToWide(utf8_lnk_path);
  if (wpath.empty()) return 0;

  HRESULT hrInit = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  IShellLinkW *psl = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_IShellLinkW, reinterpret_cast<void **>(&psl));
  if (FAILED(hr) || !psl) {
    if (SUCCEEDED(hrInit)) CoUninitialize();
    return 0;
  }
  IPersistFile *ppf = nullptr;
  int ok = 0;
  if (SUCCEEDED(psl->QueryInterface(IID_IPersistFile, reinterpret_cast<void **>(&ppf))) && ppf) {
    if (SUCCEEDED(ppf->Load(wpath.c_str(), STGM_READ))) {
      wchar_t target[MAX_PATH * 2] = {};
      if (SUCCEEDED(psl->GetPath(target, MAX_PATH * 2, nullptr, SLGP_RAWPATH))) {
        wchar_t expanded[MAX_PATH * 2] = {};
        if (ExpandEnvironmentStringsW(target, expanded, MAX_PATH * 2) > 0) {
          CopyToBuf(ToUtf8(expanded), target_buf, target_cap);
        } else {
          CopyToBuf(ToUtf8(target), target_buf, target_cap);
        }
      }
      wchar_t args[1024] = {};
      if (SUCCEEDED(psl->GetArguments(args, 1024))) CopyToBuf(ToUtf8(args), args_buf, args_cap);
      wchar_t icon[MAX_PATH * 2] = {};
      int icon_idx = 0;
      if (SUCCEEDED(psl->GetIconLocation(icon, MAX_PATH * 2, &icon_idx))) {
        wchar_t expanded[MAX_PATH * 2] = {};
        if (icon[0] && ExpandEnvironmentStringsW(icon, expanded, MAX_PATH * 2) > 0) {
          CopyToBuf(ToUtf8(expanded), icon_buf, icon_cap);
        } else {
          CopyToBuf(ToUtf8(icon), icon_buf, icon_cap);
        }
        if (out_icon_index) *out_icon_index = icon_idx;
      }
      wchar_t desc[1024] = {};
      if (SUCCEEDED(psl->GetDescription(desc, 1024))) CopyToBuf(ToUtf8(desc), desc_buf, desc_cap);
      ok = 1;
    }
    ppf->Release();
  }
  psl->Release();
  if (SUCCEEDED(hrInit)) CoUninitialize();
  return ok;
}

char *cak_known_start_menu_dirs_newline(void) {
  std::string joined;
  const KNOWNFOLDERID ids[] = {FOLDERID_CommonPrograms, FOLDERID_Programs};
  for (const auto &fid : ids) {
    PWSTR p = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(fid, 0, nullptr, &p)) && p) {
      if (!joined.empty()) joined.push_back('\n');
      joined += ToUtf8(p);
      CoTaskMemFree(p);
    }
  }
  return joined.empty() ? nullptr : DupString(joined);
}

int cak_image_dimensions(const uint8_t *data, size_t len, int *out_w, int *out_h) {
  Gdiplus::Bitmap *bmp = DecodeBitmapFromMemory(data, len);
  if (!bmp) return 0;
  if (out_w) *out_w = (int)bmp->GetWidth();
  if (out_h) *out_h = (int)bmp->GetHeight();
  delete bmp;
  return 1;
}

int cak_image_file_dimensions(const char *utf8_path, int *out_w, int *out_h) {
  EnsureGdiPlus();
  std::wstring w = ToWide(utf8_path);
  if (w.empty()) return 0;
  Gdiplus::Bitmap bmp(w.c_str());
  if (bmp.GetLastStatus() != Gdiplus::Ok || bmp.GetWidth() == 0) return 0;
  if (out_w) *out_w = (int)bmp.GetWidth();
  if (out_h) *out_h = (int)bmp.GetHeight();
  return 1;
}

uint8_t *cak_image_resize_png(const uint8_t *data, size_t len, int max_px, size_t *out_len) {
  if (out_len) *out_len = 0;
  Gdiplus::Bitmap *src = DecodeBitmapFromMemory(data, len);
  if (!src) return nullptr;
  int w = (int)src->GetWidth();
  int h = (int)src->GetHeight();
  if (w <= 0 || h <= 0 || max_px <= 0) {
    delete src;
    return nullptr;
  }
  double scale = 1.0;
  if (w > max_px || h > max_px) {
    scale = (double)max_px / (double)std::max(w, h);
  }
  int nw = std::max(1, (int)(w * scale + 0.5));
  int nh = std::max(1, (int)(h * scale + 0.5));
  Gdiplus::Bitmap dst(nw, nh, PixelFormat32bppARGB);
  {
    Gdiplus::Graphics g(&dst);
    g.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
    g.SetSmoothingMode(Gdiplus::SmoothingModeHighQuality);
    g.DrawImage(src, 0, 0, nw, nh);
  }
  delete src;
  return EncodeBitmapToPng(&dst, out_len);
}

void cak_font_metrics(
    const char *family,
    double size,
    double weight,
    double *out_ascender,
    double *out_descender,
    double *out_cap_height,
    double *out_x_height,
    double *out_leading
) {
  EnsureGdiPlus();
  std::wstring wfam = ToWide(family);
  Gdiplus::FontFamily ff(wfam.empty() ? L"Segoe UI" : wfam.c_str());
  const Gdiplus::FontFamily *use = ff.IsAvailable() ? &ff : Gdiplus::FontFamily::GenericSansSerif();
  INT style = weight >= 600.0 ? Gdiplus::FontStyleBold : Gdiplus::FontStyleRegular;
  UINT16 em = use->GetEmHeight(style);
  if (em == 0) em = 2048;
  double asc = size * (double)use->GetCellAscent(style) / (double)em;
  double desc = -size * (double)use->GetCellDescent(style) / (double)em;
  double line = size * (double)use->GetLineSpacing(style) / (double)em;
  if (out_ascender) *out_ascender = asc;
  if (out_descender) *out_descender = desc;
  if (out_cap_height) *out_cap_height = size * 0.70;
  if (out_x_height) *out_x_height = size * 0.50;
  if (out_leading) *out_leading = std::max(0.0, line - (asc - desc));
}

void cak_enable_per_monitor_dpi(void) {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
}

int cak_is_system_dark_mode(void) {
  DWORD value = 1;
  DWORD sz = sizeof(value);
  LSTATUS st = RegGetValueW(
      HKEY_CURRENT_USER,
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
      L"AppsUseLightTheme",
      RRF_RT_REG_DWORD,
      nullptr,
      &value,
      &sz);
  if (st != ERROR_SUCCESS) return 1; // Tinycast baseline is Dark
  return value == 0 ? 1 : 0;
}

void cak_window_set_backdrop(void *hwnd_ptr, int backdrop_kind, int is_dark) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  if (!hwnd) return;
  BOOL dark = is_dark ? TRUE : FALSE;
  DwmSetWindowAttribute(hwnd, 20 /* DWMWA_USE_IMMERSIVE_DARK_MODE */, &dark, sizeof(dark));
  int backdrop = backdrop_kind; // 1=None, 2=Mica, 3=Acrylic, 4=Tabbed
  DwmSetWindowAttribute(hwnd, 38 /* DWMWA_SYSTEMBACKDROP_TYPE */, &backdrop, sizeof(backdrop));
  if (backdrop_kind == 1) {
    COLORREF none_border = 0xFFFFFFFEu; // DWMWA_COLOR_NONE
    DwmSetWindowAttribute(hwnd, 34 /* DWMWA_BORDER_COLOR */, &none_border, sizeof(none_border));
    int dont_round = 1; // DWMWCP_DONOTROUND
    DwmSetWindowAttribute(hwnd, 33 /* DWMWA_WINDOW_CORNER_PREFERENCE */, &dont_round, sizeof(dont_round));
  }
}

void cak_window_set_tool_style(void *hwnd_ptr, int hide_from_taskbar, int non_activating) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  if (!hwnd) return;
  LONG_PTR ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  if (hide_from_taskbar) ex = (ex | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW;
  if (non_activating) ex |= WS_EX_NOACTIVATE;
  else ex &= ~WS_EX_NOACTIVATE;
  SetWindowLongPtrW(hwnd, GWL_EXSTYLE, ex);
}

static LRESULT CALLBACK FramelessSubclassProc(
    HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, UINT_PTR subclass_id, DWORD_PTR
) {
  switch (msg) {
    case WM_WINDOWPOSCHANGING: {
      if (lp) {
        reinterpret_cast<WINDOWPOS *>(lp)->flags |= SWP_NOCOPYBITS;
      }
      break;
    }
    case WM_NCCALCSIZE:
      return 0;
    case WM_NCPAINT:
    case 0x00AE: // WM_NCUAHDRAWCAPTION
    case 0x00AF: // WM_NCUAHDRAWFRAME
      return 0;
    case WM_NCACTIVATE:
      return TRUE;
    case WM_NCDESTROY:
      RemovePropW(hwnd, L"CAKFramelessApplied");
      RemoveWindowSubclass(hwnd, FramelessSubclassProc, subclass_id);
      break;
    default:
      break;
  }
  return DefSubclassProc(hwnd, msg, wp, lp);
}

void cak_window_apply_frameless(void *hwnd_ptr, int is_frameless) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  if (!hwnd || !IsWindow(hwnd)) return;
  constexpr UINT_PTR kFramelessSubclassId = 0xCA41F001u;
  if (!is_frameless) {
    RemovePropW(hwnd, L"CAKFramelessApplied");
    RemoveWindowSubclass(hwnd, FramelessSubclassProc, kFramelessSubclassId);
    return;
  }
  SetWindowSubclass(hwnd, FramelessSubclassProc, kFramelessSubclassId, 0);
  LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
  const LONG_PTR stripped_style =
      (style & ~(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU | WS_MINIMIZEBOX |
                 WS_MAXIMIZEBOX | WS_BORDER | WS_DLGFRAME)) |
      WS_POPUP;
  bool changed = false;
  if (stripped_style != style) {
    SetWindowLongPtrW(hwnd, GWL_STYLE, stripped_style);
    changed = true;
  }
  LONG_PTR ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  const LONG_PTR stripped_ex =
      ex & ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE);
  if (stripped_ex != ex) {
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, stripped_ex);
    changed = true;
  }
  if (!GetPropW(hwnd, L"CAKFramelessApplied")) {
    SetPropW(hwnd, L"CAKFramelessApplied", reinterpret_cast<HANDLE>(1));
    changed = true;
  }
  if (!changed) return;
  DWMNCRENDERINGPOLICY policy = DWMNCRP_ENABLED;
  DwmSetWindowAttribute(hwnd, DWMWA_NCRENDERING_POLICY, &policy, sizeof(policy));
  COLORREF none_border = 0xFFFFFFFEu;
  DwmSetWindowAttribute(hwnd, 34 /* DWMWA_BORDER_COLOR */, &none_border, sizeof(none_border));
  int dont_round = 1; // DWMWCP_DONOTROUND
  DwmSetWindowAttribute(hwnd, 33 /* DWMWA_WINDOW_CORNER_PREFERENCE */, &dont_round, sizeof(dont_round));
  SetWindowPos(
      hwnd, nullptr, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER |
          SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_NOCOPYBITS);
}

void cak_cursor_pos(double *out_x, double *out_y) {
  POINT pt{};
  GetCursorPos(&pt);
  if (out_x) *out_x = (double)pt.x;
  if (out_y) *out_y = (double)pt.y;
}

uint32_t cak_modifier_flags(void) {
  uint32_t flags = 0;
  if (GetAsyncKeyState(VK_SHIFT) & 0x8000) flags |= (1u << 17);   // .shift
  if (GetAsyncKeyState(VK_CONTROL) & 0x8000) flags |= (1u << 18); // .control
  if (GetAsyncKeyState(VK_MENU) & 0x8000) flags |= (1u << 19);    // .option
  if ((GetAsyncKeyState(VK_LWIN) | GetAsyncKeyState(VK_RWIN)) & 0x8000) flags |= (1u << 20); // .command
  if (GetKeyState(VK_CAPITAL) & 0x0001) flags |= (1u << 16);      // .capsLock
  return flags;
}

void cak_set_cursor(int cursor_kind) {
  LPCWSTR id = IDC_ARROW;
  switch (cursor_kind) {
    case 1: id = IDC_IBEAM; break;
    case 2: id = IDC_HAND; break;
    case 3: id = IDC_CROSS; break;
    case 4: id = IDC_SIZEWE; break;
    case 5: id = IDC_SIZENS; break;
    default: id = IDC_ARROW; break;
  }
  SetCursor(LoadCursorW(nullptr, id));
}

void *cak_focused_hwnd(void) {
  return GetFocus();
}

void cak_edit_get_selection(void *hwnd_ptr, int *out_start, int *out_length) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  DWORD s = 0, e = 0;
  if (hwnd) SendMessageW(hwnd, EM_GETSEL, reinterpret_cast<WPARAM>(&s), reinterpret_cast<LPARAM>(&e));
  if (out_start) *out_start = (int)s;
  if (out_length) *out_length = (int)(e >= s ? e - s : 0);
}

void cak_edit_set_selection(void *hwnd_ptr, int start, int length) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  if (!hwnd) return;
  int end = length < 0 ? -1 : (start + length);
  SendMessageW(hwnd, EM_SETSEL, (WPARAM)start, (LPARAM)end);
}

int cak_edit_has_ime_composition(void *hwnd_ptr) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  if (!hwnd) return 0;
  HIMC imc = ImmGetContext(hwnd);
  if (!imc) return 0;
  LONG bytes = ImmGetCompositionStringW(imc, GCS_COMPSTR, nullptr, 0);
  ImmReleaseContext(hwnd, imc);
  return bytes > 0 ? 1 : 0;
}

char *cak_hwnd_get_text(void *hwnd_ptr) {
  HWND hwnd = static_cast<HWND>(hwnd_ptr);
  if (!hwnd) return DupString("");
  int len = GetWindowTextLengthW(hwnd);
  if (len <= 0) return DupString("");
  std::wstring w(len + 1, L'\0');
  GetWindowTextW(hwnd, w.data(), len + 1);
  w.resize(len);
  return DupString(ToUtf8(w));
}

int cak_send_paste_chord(void) {
  INPUT inputs[4] = {};
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = VK_CONTROL;
  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 'V';
  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 'V';
  inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;
  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = VK_CONTROL;
  inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
  return SendInput(4, inputs, sizeof(INPUT)) == 4 ? 1 : 0;
}

int cak_send_unicode_text(const char *utf8_text) {
  std::wstring w = ToWide(utf8_text);
  if (w.empty()) return 1;
  std::vector<INPUT> inputs;
  inputs.reserve(w.size() * 2);
  for (wchar_t ch : w) {
    if (ch == L'\r') continue;
    if (ch == L'\n') {
      INPUT down{}, up{};
      down.type = INPUT_KEYBOARD;
      down.ki.wVk = VK_RETURN;
      up = down;
      up.ki.dwFlags = KEYEVENTF_KEYUP;
      inputs.push_back(down);
      inputs.push_back(up);
      continue;
    }
    INPUT down{}, up{};
    down.type = INPUT_KEYBOARD;
    down.ki.wScan = ch;
    down.ki.dwFlags = KEYEVENTF_UNICODE;
    up = down;
    up.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    inputs.push_back(down);
    inputs.push_back(up);
  }
  if (inputs.empty()) return 1;
  return SendInput((UINT)inputs.size(), inputs.data(), sizeof(INPUT)) == inputs.size() ? 1 : 0;
}

int cak_send_backspaces(int count) {
  if (count <= 0) return 1;
  std::vector<INPUT> inputs;
  inputs.reserve((size_t)count * 2);
  for (int i = 0; i < count; ++i) {
    INPUT down{}, up{};
    down.type = INPUT_KEYBOARD;
    down.ki.wVk = VK_BACK;
    up = down;
    up.ki.dwFlags = KEYEVENTF_KEYUP;
    inputs.push_back(down);
    inputs.push_back(up);
  }
  return SendInput((UINT)inputs.size(), inputs.data(), sizeof(INPUT)) == inputs.size() ? 1 : 0;
}

cak_win_entry *cak_enum_top_windows(int *out_count) {
  if (out_count) *out_count = 0;
  std::vector<cak_win_entry> list;
  EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
    if (!IsRealAppWindow(hwnd)) return TRUE;
    RECT r{};
    if (FAILED(DwmGetWindowAttribute(hwnd, DWMWA_EXTENDED_FRAME_BOUNDS, &r, sizeof(r)))) {
      GetWindowRect(hwnd, &r);
    }
    if (r.right <= r.left || r.bottom <= r.top) return TRUE;
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    cak_win_entry e{};
    e.hwnd = (uint64_t)(uintptr_t)hwnd;
    e.pid = (uint32_t)pid;
    e.x = r.left;
    e.y = r.top;
    e.width = r.right - r.left;
    e.height = r.bottom - r.top;
    e.is_maximized = IsZoomed(hwnd) ? 1 : 0;
    e.is_minimized = IsIconic(hwnd) ? 1 : 0;
    reinterpret_cast<std::vector<cak_win_entry> *>(lp)->push_back(e);
    return TRUE;
  }, reinterpret_cast<LPARAM>(&list));
  if (list.empty()) return nullptr;
  auto *arr = (cak_win_entry *)std::malloc(list.size() * sizeof(cak_win_entry));
  if (!arr) return nullptr;
  std::memcpy(arr, list.data(), list.size() * sizeof(cak_win_entry));
  if (out_count) *out_count = (int)list.size();
  return arr;
}

char *cak_hwnd_title(uint64_t hwnd_val) {
  return cak_hwnd_get_text(reinterpret_cast<void *>((uintptr_t)hwnd_val));
}

int cak_set_window_rect(uint64_t hwnd_val, int x, int y, int width, int height) {
  HWND hwnd = reinterpret_cast<HWND>((uintptr_t)hwnd_val);
  if (!hwnd || !IsWindow(hwnd)) return 0;
  if (IsZoomed(hwnd)) ShowWindow(hwnd, SW_RESTORE);
  // Compensate invisible Win10/11 DWM resize borders so visual frame lands on (x, y, width, height)
  RECT winRect{}, extRect{};
  if (GetWindowRect(hwnd, &winRect) &&
      SUCCEEDED(DwmGetWindowAttribute(hwnd, DWMWA_EXTENDED_FRAME_BOUNDS, &extRect, sizeof(extRect)))) {
    int leftPad = extRect.left - winRect.left;
    int topPad = extRect.top - winRect.top;
    int rightPad = winRect.right - extRect.right;
    int bottomPad = winRect.bottom - extRect.bottom;
    x -= leftPad;
    y -= topPad;
    width += leftPad + rightPad;
    height += topPad + bottomPad;
  }
  return SetWindowPos(hwnd, nullptr, x, y, width, height, SWP_NOZORDER | SWP_NOACTIVATE) ? 1 : 0;
}

int cak_control_window(uint64_t hwnd_val, int action) {
  HWND hwnd = reinterpret_cast<HWND>((uintptr_t)hwnd_val);
  if (!hwnd || !IsWindow(hwnd)) return 0;
  switch (action) {
    case 1: return ShowWindow(hwnd, SW_MINIMIZE) ? 1 : 1;
    case 2: return ShowWindow(hwnd, SW_MAXIMIZE) ? 1 : 1;
    case 3: return ShowWindow(hwnd, SW_RESTORE) ? 1 : 1;
    case 4: return PostMessageW(hwnd, WM_CLOSE, 0, 0) ? 1 : 0;
    case 5: {
      if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);
      return SetForegroundWindow(hwnd) ? 1 : 0;
    }
    default: return 0;
  }
}

int cak_lock_workstation(void) {
  return LockWorkStation() ? 1 : 0;
}

int cak_empty_recycle_bin(void) {
  HRESULT hr = SHEmptyRecycleBinW(nullptr, nullptr, SHERB_NOCONFIRMATION | SHERB_NOPROGRESSUI | SHERB_NOSOUND);
  return (SUCCEEDED(hr) || hr == E_UNEXPECTED) ? 1 : 0;
}

int cak_sha256(const uint8_t *data, size_t len, uint8_t out_digest[32]) {
  return HashBCrypt(BCRYPT_SHA256_ALGORITHM, nullptr, 0, data, len, out_digest, 32);
}

int cak_sha512(const uint8_t *data, size_t len, uint8_t out_digest[64]) {
  return HashBCrypt(BCRYPT_SHA512_ALGORITHM, nullptr, 0, data, len, out_digest, 64);
}

int cak_sha1(const uint8_t *data, size_t len, uint8_t out_digest[20]) {
  return HashBCrypt(BCRYPT_SHA1_ALGORITHM, nullptr, 0, data, len, out_digest, 20);
}

int cak_md5(const uint8_t *data, size_t len, uint8_t out_digest[16]) {
  return HashBCrypt(BCRYPT_MD5_ALGORITHM, nullptr, 0, data, len, out_digest, 16);
}

int cak_hmac_sha256(
    const uint8_t *key, size_t key_len,
    const uint8_t *data, size_t data_len,
    uint8_t out_mac[32]
) {
  return HashBCrypt(BCRYPT_SHA256_ALGORITHM, key, key_len, data, data_len, out_mac, 32);
}

int cak_aes_gcm_decrypt(
    const uint8_t *key, size_t key_len,
    const uint8_t *nonce, size_t nonce_len,
    const uint8_t *ciphertext, size_t ciphertext_len,
    const uint8_t *aad, size_t aad_len,
    const uint8_t *tag, size_t tag_len,
    uint8_t *out_plaintext
) {
  BCRYPT_ALG_HANDLE hAlg = nullptr;
  if (BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_AES_ALGORITHM, nullptr, 0) != 0) return 0;
  int ok = 0;
  if (BCryptSetProperty(
          hAlg, BCRYPT_CHAINING_MODE,
          reinterpret_cast<PUCHAR>(const_cast<wchar_t *>(BCRYPT_CHAIN_MODE_GCM)),
          sizeof(BCRYPT_CHAIN_MODE_GCM), 0) == 0) {
    BCRYPT_KEY_HANDLE hKey = nullptr;
    if (BCryptGenerateSymmetricKey(
            hAlg, &hKey, nullptr, 0, const_cast<PUCHAR>(key), (ULONG)key_len, 0) == 0) {
      BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO info;
      BCRYPT_INIT_AUTH_MODE_INFO(info);
      info.pbNonce = const_cast<PUCHAR>(nonce);
      info.cbNonce = (ULONG)nonce_len;
      info.pbAuthData = aad_len > 0 ? const_cast<PUCHAR>(aad) : nullptr;
      info.cbAuthData = (ULONG)aad_len;
      info.pbTag = const_cast<PUCHAR>(tag);
      info.cbTag = (ULONG)tag_len;
      ULONG written = 0;
      if (BCryptDecrypt(
              hKey, const_cast<PUCHAR>(ciphertext), (ULONG)ciphertext_len,
              &info, nullptr, 0, out_plaintext, (ULONG)ciphertext_len, &written, 0) == 0) {
        ok = 1;
      }
      BCryptDestroyKey(hKey);
    }
  }
  BCryptCloseAlgorithmProvider(hAlg, 0);
  return ok;
}

int cak_aes_gcm_encrypt(
    const uint8_t *key, size_t key_len,
    const uint8_t *nonce, size_t nonce_len,
    const uint8_t *plaintext, size_t plaintext_len,
    const uint8_t *aad, size_t aad_len,
    uint8_t *out_ciphertext,
    uint8_t *out_tag, size_t tag_len
) {
  BCRYPT_ALG_HANDLE hAlg = nullptr;
  if (BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_AES_ALGORITHM, nullptr, 0) != 0) return 0;
  int ok = 0;
  if (BCryptSetProperty(
          hAlg, BCRYPT_CHAINING_MODE,
          reinterpret_cast<PUCHAR>(const_cast<wchar_t *>(BCRYPT_CHAIN_MODE_GCM)),
          sizeof(BCRYPT_CHAIN_MODE_GCM), 0) == 0) {
    BCRYPT_KEY_HANDLE hKey = nullptr;
    if (BCryptGenerateSymmetricKey(
            hAlg, &hKey, nullptr, 0, const_cast<PUCHAR>(key), (ULONG)key_len, 0) == 0) {
      BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO info;
      BCRYPT_INIT_AUTH_MODE_INFO(info);
      info.pbNonce = const_cast<PUCHAR>(nonce);
      info.cbNonce = (ULONG)nonce_len;
      info.pbAuthData = aad_len > 0 ? const_cast<PUCHAR>(aad) : nullptr;
      info.cbAuthData = (ULONG)aad_len;
      info.pbTag = out_tag;
      info.cbTag = (ULONG)tag_len;
      ULONG written = 0;
      if (BCryptEncrypt(
              hKey, const_cast<PUCHAR>(plaintext), (ULONG)plaintext_len,
              &info, nullptr, 0, out_ciphertext, (ULONG)plaintext_len, &written, 0) == 0) {
        ok = 1;
      }
      BCryptDestroyKey(hKey);
    }
  }
  BCryptCloseAlgorithmProvider(hAlg, 0);
  return ok;
}

int cak_random_bytes(uint8_t *buf, size_t len) {
  if (!buf || len == 0) return 1;
  return BCryptGenRandom(nullptr, buf, (ULONG)len, BCRYPT_USE_SYSTEM_PREFERRED_RNG) == 0 ? 1 : 0;
}

} // extern "C"
#endif
