program calldll;

{$APPTYPE CONSOLE}

uses
  Windows, Classes, SysUtils;

var
  args: TList;

procedure ParseArgs(const StartIndex: Integer);
var j: Integer;
    f: Single;
    s: PChar;
begin
  args := TList.Create;
  j := StartIndex;
  while (j <= ParamCount) do begin
    if ParamStr(j) = '-f' then begin
      Inc(j);
      f := StrToFloat(ParamStr(j));
      args.Add(Pointer(f));
    end else if ParamStr(j) = '-s' then begin
      Inc(j);
      s := AllocMem(Length(ParamStr(j))+1);
      ZeroMemory(s, Length(ParamStr(j))+1);
      StrPCopy(s, ParamStr(j));
      args.Add(Pointer(s));
    end else if ParamStr(j) = '-i' then begin
      Inc(j);
      args.Add(Pointer(StrToInt(ParamStr(j))));
    end else begin
      Writeln(Format('ERROR: Cannot parse argument "%s"', [ParamStr(j)]));
      Halt;
    end;
    Inc(j);
  end;
end;

function InvokeDLL(const DLL: String; const Func: String): Integer;
var dllHnd: Cardinal;
    funcAddr: Pointer;
    j: Integer;
    pArgs: PPointerList;
const
  PTR_SIZE = sizeof(Pointer);
begin
  dllHnd := LoadLibrary(PChar(DLL));
  if dllHnd = 0 then begin
    Writeln(Format('ERROR: Could not load DLL "%s"', [DLL]));
    Halt;
  end;
  funcAddr := GetProcAddress(dllHnd, PChar(Func));
  if Cardinal(funcAddr) = 0 then begin
    Writeln(Format('ERROR: Function "%s" could not be found in "%s"', [Func, DLL]));
    Halt;
  end;
  j := args.Count;
  pArgs := Pointer(Cardinal(args.List)+(Sizeof(Pointer)*(args.Count)));

  asm
    push ecx

    // Move counter to ECX
    mov ecx, j
    cmp ecx, 0
    jz @call_func
  @next_arg:
    sub pArgs, PTR_SIZE
    //dec pArgs

    // Push an argument
    mov edx, [pArgs]
    push [edx]
    dec ecx
    jnz @next_arg

  @call_func:
    // Call function
    call funcAddr
    mov [Result], eax

    pop ecx
  end;

  FreeLibrary(dllHnd);
end;

begin
  if ParamCount < 2 then begin
    Writeln('CallDLL - version 1.0');
    Writeln('(C) 2015 Data Components Software');
    Writeln;
    Writeln('Usage: calldll[.exe] [-v] <dllfile.dll> "function name" [-i arg0 -s "arg1" -f arg2.0]');
    Writeln('  -i <arg> = Integer argument');
    Writeln('  -s <arg> = String argument');
    Writeln('  -f <arg> = Float argument');
    Writeln('NOTE: Exit code will be the return value of the DLL function');
    Writeln('      Use -v to force the exit code to remain 0');
    Halt;
  end;

  if ParamStr(1) = '-v' then begin
    ParseArgs(4);
    InvokeDLL(ParamStr(2), ParamStr(3));
  end else begin
    ParseArgs(3);
    ExitCode := InvokeDLL(ParamStr(1), ParamStr(2));
  end;
end.
