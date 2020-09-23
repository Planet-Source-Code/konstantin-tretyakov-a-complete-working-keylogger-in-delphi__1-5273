library HkLib;
{//This library contains functions to help implement
 system keyboard hook.
//}
uses
Windows;
{$R *.RES}
//-----------Data Structure to be shared------------//
type THookData=record
       Handle,Msg,
       hHook,Instances:Cardinal;
     end;
     PHookData=^THookData;
const
//--------Constants (2 stupid strings)---------------------//
   MutexName='KTKeyboardHookLibraryVersion1.00UniqueMutexName';
   MemShareName='KTKHLV100MEMFILE';
//------------------Variables-------------------------//
var
   MyMutex, //Synchronization Mutex Handle
   MemShare:Cardinal;  //Memory-Mapped File handle
   MyData:PHookData;   //Library-Shared Data
//-----------------Keyboard Hook Callback---------------//
function KbdHook(hCode,wParam:LongInt;lParam:LongInt):Longint;stdcall;
begin
     try
       WaitForSingleObject(MyMutex,INFINITE); //Synchronize
       if (MyData^.Msg<>0) and (hCode=HC_ACTION) then PostMessage(MyData^.Handle,MyData^.Msg,wParam,lParam);
       if MyData^.hHook <> 0 then Result:=CallNextHookEx(MyData^.hHook,hCode,wParam,lParam)
          else Result:=0;
     finally ReleaseMutex(MyMutex);
     end;
end;
//-------------Function to set hook----------------//
function HookKeyboard(Hwnd,MsgID:Cardinal):LongInt;stdcall;
begin
     try
     WaitForSingleObject(MyMutex,INFINITE); //Synchronize
     if MyData^.hHook<>0 then begin
        Result:=0;ReleaseMutex(MyMutex);Exit;
     end;
     Result:=SetWindowsHookEx(WH_KEYBOARD,@KbdHook,HInstance,0);
     if Result<>0 then begin
        MyData^.hHook:=Result;
        MyData^.Msg:=MsgID;
        MyData^.Handle:=Hwnd;
     end;
     finally ReleaseMutex(MyMutex);
     end;
end;
//------------------Function to remove Hook----------------//
function UnhookKeyboard:Boolean;stdcall;
begin
     try
      WaitForSingleObject(MyMutex,INFINITE);
      Result:=True;
      if MyData^.hHook=0 then begin
         ReleaseMutex(MyMutex);Exit;
      end;
      Result:=UnhookWindowsHookEx(MyData^.hHook);
      if Result=True then begin
         MyData^.hHook:=0; MyData^.Msg:=0; MyData^.Handle:=0;
      end;
     finally ReleaseMutex(MyMutex);
     end;
end;
//-----------Function to determine, whether we are already hooked-----------//
function Hooked:Boolean;stdcall;
begin
     WaitForSingleObject(MyMutex,INFINITE);
     Result:=(MyData^.hHook<>0);
     ReleaseMutex(MyMutex);
end;
//=========================DLL Mechanics======================//
//--------------Initialization Code--------------//
procedure EnterDLL;stdcall;
var FirstInstance:Boolean;
begin
//Get a Mutex for synchronization
     MyMutex:=CreateMutex(nil,True,MutexName);
//Open Memory Share
     MemShare:=OpenFileMapping(FILE_MAP_ALL_ACCESS,False,PChar(MemShareName));
     FirstInstance:=(MemShare=0);
//If cannot open, then create
     if MemShare=0 then MemShare:=CreateFileMapping($FFFFFFFF,nil,PAGE_READWRITE,0,SizeOf(THookData),MemShareName);
     if MemShare<>0 then begin
        //we are opened for the first time...
        MyData:=MapViewOfFile(MemShare,FILE_MAP_ALL_ACCESS,0,0,0);
        if Firstinstance then with MyData^ do begin
           Handle:=0;Msg:=0;hHook:=0;Instances:=0;
        end;
        MyData^.Instances:=MyData^.Instances+1;
     end;
     ReleaseMutex(MyMutex);
end;
//--------------DeInitialization Code---------------//
procedure ExitDLL;stdcall;
begin
    try
//Synchronize
      WaitForSingleObject(MyMutex,INFINITE);
      MyData^.Instances:=MyData^.Instances-1;
      if (MyData^.Instances=0) then begin
//Close shared memory file and synchronization mutex
         UnmapViewOfFile(MyData);
         CloseHandle(MemShare);
         CloseHandle(MyMutex);
       end;
     finally ReleaseMutex(MyMutex);
     end;
end;
//-----------------DllEntryPoint----------//
procedure LibraryProc(Reason: Integer);
begin
 case Reason of
   DLL_PROCESS_DETACH:ExitDll;
   DLL_PROCESS_ATTACH:EnterDll;
 end;
end;
//-----------------Exports...-----------------//
exports HookKeyboard,UnhookKeyboard,Hooked;
//--------------------------------------------------------//
begin
EnterDLL;
DllProc:=@LibraryProc;
end.
