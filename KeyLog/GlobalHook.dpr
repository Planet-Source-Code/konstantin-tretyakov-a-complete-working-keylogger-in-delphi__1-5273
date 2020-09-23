program GlobalHook;

uses
  Forms,
  ufGlobHook in 'ufGlobHook.pas' {frmHook};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Keyboard Hook';
  Application.CreateForm(TfrmHook, frmHook);
  Application.Run;
end.
