// DemoServerController.cpp : Defines the entry point for the application.
//
#define UNICODE // Ensures wide-character versions of Windows API functions
#define _WIN32_WINNT 0x0600 // Targets Windows Vista or later (required for ShellExecuteW)


#include "framework.h"
#include "DemoServerController.h"
#include <iostream>
#include <string>
#include <cstdlib>
#include <winsock2.h> // For Windows sockets
#include <ws2tcpip.h> // For inet_pton and related functions
#include <iphlpapi.h>
#include <icmpapi.h>
#include <vector>

// Link with Iphlpapi.lib
#pragma comment(lib, "Iphlpapi.lib")
#pragma comment(lib, "Ws2_32.lib")

#define MAX_LOADSTRING 100

HWND hOutputBox;

// Global Variables:
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name

// Forward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
    _In_opt_ HINSTANCE hPrevInstance,
    _In_ LPWSTR    lpCmdLine,
    _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // Initialize global strings
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_DEMOSERVERCONTROLLER, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

    // Perform application initialization:
    if (!InitInstance(hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_DEMOSERVERCONTROLLER));

    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int)msg.wParam;
}

//
//  FUNCTION: ShutdownServer()
//
//  PURPOSE: Send command to shutdown the server
//
void ShutdownServer(HWND hOutputBox) {
    std::string ipAddress = "192.168.3.62";
    std::string username = "root";
    std::string password = "Asdf370)";
    std::string command = "curl -X POST http://192.168.3.62:5000/shutdown -H \"Authorization: Bearer 4443\"";
    std::wstring output = L"";

    if (system(command.c_str())) {
        output = L"Server is shutting down successfully.";
    }
    else{
        output = L"Failed to shut down the server.";
    }
    // Update the static text box with the result
    if (!SetWindowTextW(hOutputBox, output.c_str())) {
        MessageBoxW(nullptr, L"Failed to update the output text box.", L"Error", MB_OK | MB_ICONERROR);
    }
}

//
// Function TestPing(string&) 
//
//
bool TestPing(const std::string& ipAddress) {
    HANDLE hIcmpFile;
    DWORD dwRetVal;
    char sendData[32] = "Ping Test Data";
    LPVOID replyBuffer;
    DWORD replySize;
    DWORD timeout = 1000; // Timeout in milliseconds

    std::wstring wideIpAddress(ipAddress.begin(), ipAddress.end());

    // Convert the IP address to binary format
    IN_ADDR ipAddr;
    if (InetPton(AF_INET, wideIpAddress.c_str(), &ipAddr) != 1) {
        std::cerr << "Invalid IP address: " << ipAddress << std::endl;
        return false;
    }

    // Open an ICMP handle
    hIcmpFile = IcmpCreateFile();
    if (hIcmpFile == INVALID_HANDLE_VALUE) {
        std::cerr << "Failed to create ICMP handle. Error: " << GetLastError() << std::endl;
        return false;
    }

    // Allocate memory for the reply buffer
    replySize = sizeof(ICMP_ECHO_REPLY) + sizeof(sendData);
    replyBuffer = malloc(replySize);
    if (replyBuffer == nullptr) {
        std::cerr << "Failed to allocate memory for the reply buffer." << std::endl;
        IcmpCloseHandle(hIcmpFile);
        return false;
    }

    // Send the ping
    dwRetVal = IcmpSendEcho(
        hIcmpFile,               // Handle returned by IcmpCreateFile
        ipAddr.S_un.S_addr,      // Destination IP address
        sendData,                // Data to send
        sizeof(sendData),        // Size of data
        NULL,                    // Request options
        replyBuffer,             // Reply buffer
        replySize,               // Size of reply buffer
        timeout                  // Timeout
    );

    // Process the results
    if (dwRetVal > 0) {
        auto* echoReply = (PICMP_ECHO_REPLY)replyBuffer;
        std::cout << "Ping succeeded. Roundtrip time: " << echoReply->RoundTripTime << "ms" << std::endl;
    }
    else {
        std::cerr << "Ping failed. Error: " << GetLastError() << std::endl;
        free(replyBuffer);
        IcmpCloseHandle(hIcmpFile);
        return false;
    }

    // Clean up
    free(replyBuffer);
    IcmpCloseHandle(hIcmpFile);
    return true;
}

//
// Function TestConnection(string, int) 
//
// Purpose: to test the connection to the connected device 
//
void TestConnection(const std::string& ipAddress, HWND hOutputBox) {
    std::wstring output;

    //int result = system("ping 192.168.3.62");
    //if (result == 0) {
    if(TestPing(ipAddress)){
        output = L"Connected";
    }
    else {
        output = L"Failed to Connect"; 
    }

    // Update the static text box with the result
    if (!SetWindowTextW(hOutputBox, output.c_str())) {
        MessageBoxW(nullptr, L"Failed to update the output text box.", L"Error", MB_OK | MB_ICONERROR);
    }
}


void OpenURL(const std::string& url, HWND hOutputBox) {
    // Convert the URL to a wide string (needed for ShellExecuteW)
    std::wstring wideURL(url.begin(), url.end());

    // Use ShellExecute to open the URL
    std::string chromePath = "\"C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe\"";
    std::string command = chromePath + " " + url;

    int result = system(command.c_str());
    std::wstring output;


    if (result != 0) {
        output = L"Failed to open URL. Error code: " + (int)result;
    }
    else {
        output = L"Successfully opened v9 URL ";
    }
    // Update the static text box with the result
    if (!SetWindowTextW(hOutputBox, output.c_str())) {
        MessageBoxW(nullptr, L"Failed to update the output text box.", L"Error", MB_OK | MB_ICONERROR);
    }

}

//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.cbClsExtra = 0;
    wcex.cbWndExtra = 0;
    wcex.hInstance = hInstance;
    wcex.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_DEMOSERVERCONTROLLER));
    wcex.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wcex.lpszMenuName = MAKEINTRESOURCEW(IDC_DEMOSERVERCONTROLLER);
    wcex.lpszClassName = szWindowClass;
    wcex.hIconSm = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
    hInst = hInstance; // Store instance handle in our global variable

    HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, 0, 400, 500, nullptr, nullptr, hInstance, nullptr);

    if (!hWnd)
    {
        return FALSE;
    }

    ShowWindow(hWnd, nCmdShow);
    UpdateWindow(hWnd);

    return TRUE;
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE: Processes messages for the main window.
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_CREATE:
        // Create a static text box to display the output
        hOutputBox = CreateWindowW(L"STATIC", L"Shutdown Message", WS_CHILD | WS_VISIBLE | SS_LEFT,
            50, 50, 300, 50, hWnd, (HMENU)2, hInst, NULL);
        if (!hOutputBox) {
            MessageBoxW(hWnd, L"Failed to create output text box.", L"Error", MB_OK | MB_ICONERROR);
        }

        // Create the button
        CreateWindowW(L"BUTTON", L"Shutdown Server", WS_TABSTOP | WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON,
            50, 100, 150, 30, hWnd, (HMENU)1, hInst, NULL);

        // Create Another Button
        CreateWindowW(L"Button", L"Test Connection", WS_TABSTOP | WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON,
            50, 150, 150, 30, hWnd, (HMENU)2, hInst, NULL);

        // Create Another Button
        CreateWindowW(L"Button", L"Open v9", WS_TABSTOP | WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON,
            50, 200, 150, 30, hWnd, (HMENU)3, hInst, NULL);

        break;

    case WM_COMMAND:
    {
        int wmId = LOWORD(wParam);
        switch (wmId)
        {
        case IDM_ABOUT:
            DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
            break;
        case IDM_EXIT:
            DestroyWindow(hWnd);
            break;
        default:
            if (wmId == 1) { // Button ID is 1
                ShutdownServer(hOutputBox); // Pass the static text box handle
            }
            else if(wmId == 2){//Button ID is 2
                TestConnection("192.168.3.62", hOutputBox); //Pass the static text box handle 
            }
            else if(wmId == 3){//Button ID is 3
                OpenURL("https://192.168.3.62/artsentry", hOutputBox); 
            }
            break;
        }
    }
    break;

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        EndPaint(hWnd, &ps);
    }
    break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
