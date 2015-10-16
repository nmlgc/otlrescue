;
; Canon CaptureOnTouch temp file rescuer - Win32 version
;

; Win32 API
; ---------
; Types
LPWSTR typedef ptr word
HANDLE typedef dword

; Functions
CloseHandle proto stdcall :HANDLE
CommandLineToArgvW proto stdcall :LPWSTR, :ptr dword
CreateFileW proto stdcall :LPWSTR, :dword, :dword, :ptr, :dword, :dword, :HANDLE
GetCommandLineW proto stdcall
GetProcessHeap proto stdcall
GetStdHandle proto stdcall :dword
HeapAlloc proto stdcall :HANDLE, :dword, :dword
HeapFree proto stdcall :HANDLE, :dword, :ptr
ReadFile proto stdcall :HANDLE, :ptr, :dword, :ptr dword, :ptr
WriteConsoleW proto stdcall :HANDLE, :LPWSTR, :dword, :ptr dword, :ptr
WriteFile proto stdcall :HANDLE, :ptr, :dword, :ptr dword, :ptr

; Output streams
STD_INPUT_HANDLE equ -10
STD_OUTPUT_HANDLE equ -11
STD_ERROR_HANDLE equ -12

; CreateFile: dwDesiredAccess
GENERIC_READ equ 80000000h
GENERIC_WRITE equ 40000000h
GENERIC_EXECUTE equ 20000000h
GENERIC_ALL equ 10000000h

; CreateFile: dwShareMode
FILE_SHARE_READ equ 1h
FILE_SHARE_WRITE equ 2h
FILE_SHARE_DELETE equ 4h

; CreateFile: dwCreationDisposition
CREATE_NEW equ 1
CREATE_ALWAYS equ 2
OPEN_EXISTING equ 3
OPEN_ALWAYS equ 4
TRUNCATE_EXISTING equ 5

; CreateFile: dwFlagsAndAttributes
FILE_ATTRIBUTE_READONLY equ 1h
FILE_ATTRIBUTE_HIDDEN equ 2h
FILE_ATTRIBUTE_SYSTEM equ 4h
FILE_ATTRIBUTE_DIRECTORY equ 10h
FILE_ATTRIBUTE_ARCHIVE equ 20h
FILE_ATTRIBUTE_NORMAL equ 80h
FILE_ATTRIBUTE_TEMPORARY equ 100h
FILE_ATTRIBUTE_COMPRESSED equ 800h
; ---------

; File structures
; ---------------
CANONHEADER struct
	chWidth dd ?
	chHeight dd ?
	chBytesPerPixel dd ?
	chBitsPerByte dd ?
	chDPI_X dd ?
	chDPI_Y dd ?
	chNull dd ?
	chRowStride dd ?
	chOne dd ?
	dd 23 dup(?)
CANONHEADER ends

BITMAPFILEHEADER struct
	bfType dw ?
	bfSize dd ?
	bfReserved1 dw ?
	bfReserved2 dw ?
	bfOffBits dd ?
BITMAPFILEHEADER ends

; BITMAPINFOHEADER: biCompression
BI_RGB equ 0
BI_RLE8 equ 1
BI_RLE4 equ 2
BI_BITFIELDS equ 3

BITMAPINFOHEADER struct
	biSize dd ?
	biWidth dd ?
	biHeight dd ?
	biPlanes dw ?
	biBitCount dw ?
	biCompression dd ?
	biSizeImage dd ?
	biXPelsPerMeter dd ?
	biYPelsPerMeter dd ?
	biClrUsed dd ?
	biClrImportant dd ?
BITMAPINFOHEADER ends
; ---------------

ceil macro reg, val
	add reg, val - 1
	and reg, not (val - 1)
endm

wnstring macro sym, val:vararg
	sym dw val
	sym#_len dd ($-sym) / 2
endm

	.data

wnstring output_ext, ".bmp", 0

str_usage dw "Please pass one or more otl*.tmp files.", 0
str_ellipsis dw "...", 0
str_ok dw " OK", 0Ah, 0

	.data?

stdout dd ?
stderr dd ?

	.code

wcslen proc uses ecx, edi string:LPWSTR
	mov edi, string
	mov ecx, -1
	xor eax, eax
	cld
	repne scasw
	sub edi, string
	shr edi, 1
	dec edi
	mov eax, edi
wcslen endp

wfputs proc uses ecx, handle:HANDLE, string:LPWSTR
	local byte_ret:dword

	invoke wcslen, string
	mov ecx, eax
	invoke WriteConsoleW, handle, string, ecx, addr byte_ret, 0
wfputs endp

; Separate function to not mess up the stack frame with the name allocation.
otlrescue_open proc filename:LPWSTR
	; Construct the output file name
	invoke wcslen, filename
	mov ecx, eax ; Necessary for rep movsw
	add eax, output_ext_len

	shl eax, 1
	ceil eax, 4
	sub esp, eax

	cld
	mov edi, esp
	mov esi, filename
	rep movsw
	mov esi, addr output_ext
	mov ecx, output_ext_len
	rep movsw
	mov esi, esp

	; TODO: Maybe we shouldn't overwrite the file?
	invoke CreateFileW, esi, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
otlrescue_open endp

otlrescue proc uses esi, filename:LPWSTR
	local otl_handle:HANDLE, otl_header:CANONHEADER
	local bmp_handle:HANDLE, bmp_file:BITMAPFILEHEADER, bmp_info:BITMAPINFOHEADER
	local row:ptr, row_len_padded:dword
	local byte_ret:dword

	invoke CreateFileW, filename, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0
	mov [otl_handle], eax
	; TODO: Error message, with format strings!

	invoke ReadFile, [otl_handle], addr otl_header, sizeof CANONHEADER, addr byte_ret, 0
	; TODO: Error message, with format strings!

	xor edx, edx
	mov eax, [otl_header.chRowStride]
	mov ecx, eax
	ceil ecx, 4
	mov [row_len_padded], ecx
	mul [otl_header.chHeight]

	mov [bmp_file.bfType], 'MB' ; Little-endian!
	mov ecx, sizeof BITMAPFILEHEADER + sizeof BITMAPINFOHEADER
	mov [bmp_file.bfOffBits], ecx
	add eax, ecx
	mov [bmp_file.bfSize], eax

	mov [bmp_info.biSize], sizeof BITMAPINFOHEADER
	mov eax, [otl_header.chWidth]
	mov [bmp_info.biWidth], eax
	mov eax, [otl_header.chHeight]
	neg eax
	mov [bmp_info.biHeight], eax
	mov [bmp_info.biPlanes], 1
	mov [bmp_info.biCompression], BI_RGB
	xor eax, eax
	mov [bmp_file.bfReserved1], ax
	mov [bmp_file.bfReserved2], ax
	mov [bmp_info.biXPelsPerMeter], eax
	mov [bmp_info.biYPelsPerMeter], eax
	mov [bmp_info.biSizeImage], eax
	mov [bmp_info.biClrUsed], eax
	mov [bmp_info.biClrImportant], eax

	mov eax, [otl_header.chBytesPerPixel]
	mul [otl_header.chBitsPerByte]
	mov [bmp_info.biBitCount], ax

	invoke otlrescue_open, filename
	mov [bmp_handle], eax

	invoke WriteFile, [bmp_handle], addr bmp_file, sizeof bmp_file, addr byte_ret, 0
	invoke WriteFile, [bmp_handle], addr bmp_info, sizeof bmp_info, addr byte_ret, 0

	invoke GetProcessHeap
	invoke HeapAlloc, eax, 0, [row_len_padded]
	; TODO: Error checking!
	mov [row], eax

	mov ecx, [otl_header.chHeight]
	@@rowloop:
		push ecx
		invoke ReadFile, [otl_handle], [row], [otl_header.chRowStride], addr byte_ret, 0

		mov esi, [row] ; Row base pointer
		.if [otl_header.chBytesPerPixel] == 3
			xor ecx, ecx ; Pixel
			.while ecx < [otl_header.chWidth]
				; TODO: Are there more modern instructions for this?
				lea eax, [ecx+ecx*2]
				lea ebx, [esi+eax]
				mov eax, [ebx]
				mov [ebx+2], al
				shr eax, 16
				mov [ebx+0], al
			inc ecx
			.endw
		.endif
		invoke WriteFile, [bmp_handle], [row], [row_len_padded], addr byte_ret, 0
		pop ecx
	loop @@rowloop

	invoke wfputs, [stdout], addr str_ok
	mov eax, 0

	invoke GetProcessHeap
	invoke HeapFree, eax, 0, [row]
	invoke CloseHandle, [bmp_handle]
	invoke CloseHandle, [otl_handle]
otlrescue endp

public main
main proc
	local argv:LPWSTR, argc:sdword

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov [stdout], eax
	invoke GetStdHandle, STD_ERROR_HANDLE
	mov [stderr], eax

	invoke GetCommandLineW
	mov ebx, eax
	invoke CommandLineToArgvW, ebx, addr argc
	mov [argv], eax

	.if [argc] < 2
		invoke wfputs, [stderr], addr str_usage
		mov eax, -1
		ret
	.endif

	mov esi, 1 ; Skip argv[0]
	.repeat
		mov ebx, [argv]
		mov edi, [ebx+esi*4]
		invoke wfputs, [stdout], edi
		invoke wfputs, [stdout], addr str_ellipsis
		invoke otlrescue, edi
	inc esi
	.until esi == [argc]

	mov eax, 0
main endp