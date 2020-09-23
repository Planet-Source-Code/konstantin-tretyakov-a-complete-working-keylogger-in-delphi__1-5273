unit ufGlobHook;

interface

uses
  Windows, Messages, SysUtils, Forms, StdCtrls, Classes, Controls;
const
     LibInst:HInst=0;
     hHk:HHOOK=0;
     MSG_KBD=WM_APP+12321;
type
  TfrmHook = class(TForm)
    txtStatus: TMemo;
    Button1: TButton;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure KbdMsg(var Msg:TMessage);message MSG_KBD;
  private
    { Private declarations }
  public
    { Public declarations }
  end;
function HookKeyboard(Hwnd,MsgID:Cardinal):LongInt;stdcall;external 'HkLib.dll' name 'HookKeyboard';
function UnhookKeyboard:Boolean;stdcall;external 'HkLib.dll' name 'UnhookKeyboard';
function Hooked:Boolean;stdcall;external 'HkLib.dll' name 'Hooked';

var
  frmHook: TfrmHook;
const
  CtlChars:set of Byte=[1..12,14..31];
implementation
{$R *.DFM}
procedure TfrmHook.KbdMsg(var Msg:TMessage);
var KN:PChar;tmpRes:Integer; KS:TKeyBoardState; ch:String;
lp,wp:LongInt;
label Bye;
begin
     lp:=Msg.lParam;wp:=Msg.wParam;
     if ((lp and $80000000)=0) then begin
        KN:=StrAlloc(2);
        if GetKeyboardState(KS)=False then goto Bye;
        tmpRes:=ToAscii(wp,lp,KS,KN,0);
        if (tmpRes=1) and not(Ord(String(KN)[1])in CtlChars) then begin
           ch:=String(KN)[1];
           if ord(ch[1])=13 then ch:=ch+#10;
           frmHook.txtStatus.Text:=frmHook.txtStatus.Text+ch;
        end else begin
           KN:=StrAlloc(10);
           if GetKeyNameText(lp,KN,10)<> 0 then begin
              frmHook.txtStatus.Text:=frmHook.txtStatus.Text+'{'+String(KN)+'}';
           end;
       end;
     end;
Bye:
end;
procedure TfrmHook.Button2Click(Sender: TObject);
begin
     if hHk=0 then Exit;
     if UnhookKeyboard=False then
        MessageBox(Handle,'Failed','Error',MB_ICONHAND)
     else begin
         hHk:=0;
         Button1.Enabled:=True;
     end;
end;
procedure TfrmHook.Button1Click(Sender: TObject);
begin
      hHk:=HookKeyboard(Handle,MSG_KBD);
      if hHk=0 then MessageBox(Handle,'Failed','Error',MB_ICONERROR)
        else begin
        Button1.Enabled:=False;
      end;
end;

end.
