#include "pch.h"

BOOL APIENTRY DllMain( HMODULE hModule,
					   DWORD  ul_reason_for_call,
					   LPVOID lpReserved
					 )
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}

#include <Windows.h>
#include <Psapi.h>
#include <tchar.h>
#include <stdlib.h>

#define MAX_TITLE_LENGTH 256
static const char prefix[] = "C:\\Windows\\";
static const char gameBarExe[] = "GameBar.exe";

BOOL TestFullscreen(HWND hwnd) {
	WINDOWPLACEMENT wp;
	wp.length = sizeof(WINDOWPLACEMENT);
	if (!GetWindowPlacement(hwnd, &wp))
		return FALSE;
	if (IsZoomed(hwnd))
		return TRUE;
	RECT rcDesktop;
	GetClientRect(GetDesktopWindow(), &rcDesktop);
	return (wp.rcNormalPosition.left <= rcDesktop.left &&
		wp.rcNormalPosition.top <= rcDesktop.top &&
		wp.rcNormalPosition.right >= rcDesktop.right &&
		wp.rcNormalPosition.bottom >= rcDesktop.bottom);
}

void ConvertTCHARToChar(const TCHAR* source, char* dest, size_t destSize) {
#ifdef _WIN32
	wcstombs_s(NULL, dest, destSize, source, _TRUNCATE);
#else
	wcstombs(dest, source, destSize);
#endif
}

__declspec(dllexport) int get_running_fullscreen_game_path(char* buffer, int bufferSize) {
	HWND hwnd = NULL;
	while ((hwnd = FindWindowEx(NULL, hwnd, NULL, NULL)) != NULL) {
		if (TestFullscreen(hwnd)) {
			TCHAR windowTitle[MAX_TITLE_LENGTH];
			GetWindowText(hwnd, windowTitle, MAX_TITLE_LENGTH);

			DWORD processId;
			GetWindowThreadProcessId(hwnd, &processId);

			HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
			if (hProcess == NULL) {
				return 1;
			}

			TCHAR executablePath[MAX_PATH];
			if (GetModuleFileNameEx(hProcess, NULL, executablePath, MAX_PATH) == 0) {
				CloseHandle(hProcess);
				return 1;
			}

			CloseHandle(hProcess);
			size_t exe_bufferSize = sizeof(executablePath) / sizeof(executablePath[0]);

			char* charPath = (char*)malloc(exe_bufferSize);

			ConvertTCHARToChar(executablePath, charPath, exe_bufferSize);
			int result = strncmp(charPath, prefix, 11);
			if (result == 0) {
				continue;
			}

			result = strcmp(charPath + strlen(charPath) - 11, gameBarExe);
			if (result == 0) {
				continue;
			}
			
			strcpy_s(buffer, bufferSize, charPath); // Use charPath as a regular char array
			free(charPath);
			return 0;

		}
	}
	return 1; 
}
