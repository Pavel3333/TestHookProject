; DirectX 9 hooking tool
; author: Mikhail Remiozv aka keng
; release date: 22.08.2014
; language: flat assembler
; tools needed: fasm 1.7x (www.flatassembler.net)

format PE NATIVE 4.0
entry start

macro cominvoke object,proc,[arg]
 { common
    if ~ arg eq
   reverse
     pushd arg
   common
    end if
    mov eax,object
    push eax
    mov eax,[eax]
    call dword[eax+proc*4] }

include 'win32a.inc'

section '.text' code readable executable

start:
    xor 	ebx,ebx
    invoke	GetDesktopWindow
    mov 	[hWnd],eax
    call	GetDX9Methods
    cominvoke	[pD3DDevice],42
    invoke	ExitProcess,ebx

proc GetDX9Methods
    invoke	LoadLibraryA,d3d9dllname
    mov 	[d3d9dll],eax
    invoke	GetProcAddress,[d3d9dll],d3dcreate
    push	32 ; SDK_VERSION
    call	eax
    ;mov	 [pD3D],eax
    mov 	[d3dpp.SwapEffect],3
    mov 	[d3dpp.Windowed],1
    cominvoke	[eax],16,ebx,1,[hWnd],0x120,d3dpp,pD3DDevice ; 16 = CreateDevice offset

    mov 	eax,[pD3DDevice]
    stdcall	replace,[eax],42,MyEndScene,EndScene ; 42 = EndScene offset
    ret
endp

proc replace IntTblAddr,MethodNumber,NewFunction,SaveOldFunction
     push	eax
     push	ebx
     mov	eax,[MethodNumber]
     shl	eax,2
     add	eax,[IntTblAddr]
     mov	ebx,[eax]
     cmp	[NewFunction],ebx
     je 	AlreadyReplaced
     push	eax
     mov	eax,[SaveOldFunction]
     mov	[eax],ebx
     mov	eax,[esp]
     invoke	VirtualQuery,eax,mbi,MEMORY_BASIC_INFORMATIONsz
     mov	eax,[esp]
     push	[mbi.Protect]
     invoke	VirtualProtect,eax,4,PAGE_EXECUTE_READWRITE,esp
     add	esp,4
     pop	eax
     mov	ebx,[NewFunction]
     mov	[eax],ebx
     push	PAGE_EXECUTE_READWRITE
     invoke	VirtualProtect,eax,4,[mbi.Protect],esp
     add	esp,4
AlreadyReplaced:
     pop	ebx
     pop	eax
     ret
endp

proc MyEndScene obj
     int 3
     invoke EndScene,[obj]
     ret
endp

section '.data' data readable writeable
  d3d9dll dd 0
  d3dcreate db "Direct3DCreate9",0
  d3d9dllname db "d3d9",0
  class db "STATIC",0
  ;pD3D dd 0
  pD3DDevice dd 0
  hWnd dd 0
  Release dd 0
  EndScene dd 0

struc MEMORY_BASIC_INFORMATION
{
	.BaseAddress		 dd ?
	.AllocationBase 	 dd ?
	.AllocationProtect	 dd ?
	.RegionSize		 dd ?
	.State			 dd ?
	.Protect		 dd ?
	.Type			 dd ?
}
MEMORY_BASIC_INFORMATIONsz = 7*4

mbi MEMORY_BASIC_INFORMATION

struct lala
BackBufferWidth dd ?
BackBufferHeight dd ?
BackBufferFormat dd ?
BackBufferCount dd ?
MultiSampleType dd ?
MultiSampleQuality dd ?
SwapEffect dd ?
hDeviceWindow dd ?
Windowed dd ?
EnableAutoDepthStencil dd ?
AutoDepthStencilFormat dd ?
Flags dd ?
FullScreen_RefreshRateInHz dd ?
PresentationInterval dd ?
ends

d3dpp lala 0

section '.idata' import data readable writeable
  library kernel32,'KERNEL32.DLL',\
	  user32,'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
