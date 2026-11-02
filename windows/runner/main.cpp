#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shellapi.h>
#include <windows.h>
#include <memory>
#include <optional>
#include <cstdlib>
#include <string>
#include <vector>
#include "flutter/generated_plugin_registrant.h"

namespace {
std::unique_ptr<flutter::FlutterViewController> controller;

std::vector<std::string> CommandLineArguments() {
  int count = 0;
  LPWSTR* args = CommandLineToArgvW(GetCommandLineW(), &count);
  std::vector<std::string> result;
  if (args == nullptr) return result;
  for (int i = 1; i < count; ++i) {
    const int length = WideCharToMultiByte(CP_UTF8, 0, args[i], -1, nullptr, 0, nullptr, nullptr);
    if (length <= 1) continue;
    std::string value(static_cast<size_t>(length), '\0');
    WideCharToMultiByte(CP_UTF8, 0, args[i], -1, value.data(), length, nullptr, nullptr);
    value.pop_back();
    result.push_back(value);
  }
  LocalFree(args);
  return result;
}

LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  if (controller) {
    std::optional<LRESULT> result = controller->HandleTopLevelWindowProc(window, message, wparam, lparam);
    if (result) return *result;
  }
  switch (message) {
    case WM_SIZE:
      if (controller) {
        RECT rect;
        GetClientRect(window, &rect);
        MoveWindow(controller->view()->GetNativeWindow(), 0, 0,
                   rect.right - rect.left, rect.bottom - rect.top, TRUE);
      }
      return 0;
    case WM_SETFOCUS:
      if (controller) SetFocus(controller->view()->GetNativeWindow());
      return 0;
    case WM_FONTCHANGE:
      if (controller) controller->engine()->ReloadSystemFonts();
      return 0;
    case WM_DPICHANGED: {
      auto suggested = reinterpret_cast<RECT*>(lparam);
      SetWindowPos(window, nullptr, suggested->left, suggested->top,
                   suggested->right - suggested->left,
                   suggested->bottom - suggested->top, SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }
    case WM_DESTROY:
      controller.reset();
      PostQuitMessage(0);
      return 0;
  }
  return DefWindowProc(window, message, wparam, lparam);
}
}  // namespace

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE, wchar_t*, int show_command) {
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  const wchar_t class_name[] = L"CHESS_2_FLUTTER_WINDOW";
  WNDCLASS window_class{};
  window_class.lpfnWndProc = WindowProc;
  window_class.hInstance = instance;
  window_class.lpszClassName = class_name;
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.hIcon = LoadIcon(instance, MAKEINTRESOURCE(101));
  RegisterClass(&window_class);
  HWND window = CreateWindow(class_name, L"Шахматы 2.0", WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, CW_USEDEFAULT, 1440, 960, nullptr, nullptr, instance, nullptr);
  if (!window) { CoUninitialize(); return EXIT_FAILURE; }
  RECT rect;
  GetClientRect(window, &rect);
  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(CommandLineArguments());
  controller = std::make_unique<flutter::FlutterViewController>(
      rect.right - rect.left, rect.bottom - rect.top, project);
  if (!controller->engine() || !controller->view()) {
    controller.reset(); DestroyWindow(window); CoUninitialize(); return EXIT_FAILURE;
  }
  RegisterPlugins(controller->engine());
  SetParent(controller->view()->GetNativeWindow(), window);
  MoveWindow(controller->view()->GetNativeWindow(), 0, 0,
             rect.right - rect.left, rect.bottom - rect.top, TRUE);
  controller->engine()->SetNextFrameCallback([window, show_command]() {
    ShowWindow(window, show_command);
    UpdateWindow(window);
  });
  controller->ForceRedraw();
  MSG message;
  while (GetMessage(&message, nullptr, 0, 0) > 0) {
    TranslateMessage(&message);
    DispatchMessage(&message);
  }
  controller.reset();
  UnregisterClass(class_name, instance);
  CoUninitialize();
  return EXIT_SUCCESS;
}
