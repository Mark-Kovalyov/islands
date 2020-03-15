//Остров разбит на правильные шестиугольные ячейки площади 1 различной высоты над уровнем моря.
//Найти максимальный объем воды, которая не стечет в море после долгих проливных дождей
//или прилива заданной высоты. Решить ту же задачу для квадратных ячеек с 4 и 8 соседями.
type
  TCell= packed record
    Height: byte;
    Level: byte;
    Dir: shortInt;
    end;

  TSetLevel= procedure(xy: integer);

var
  XCount: integer;
  YCount: integer;
  XYCount: integer;
  WHCount: integer;
  Map: packed array of TCell;
  Order: array of integer;
  Links: array[0..7] of integer;

//чтение карты из файла
function ReadMap(const aFileName: string): boolean;
var
  bm: TBitMap;
  p: pByteArray;
  x, y: integer;
begin;
  bm:=TBitmap.Create;
  try
    bm.LoadFromFile('..\bmp\ShaImg512_01.bmp');
    Result:=(bm.PixelFormat=pf24bit);
    if Result then begin;
      WHCount:=bm.Width * bm.Height; SetLength(Order, WHCount);
      XCount:=bm.Width+2;
      YCount:=bm.Height+2;
      XYCount:=XCount * YCount; SetLength(Map, XYCount);
      for x:=0 to XCount-1 do with Map[0*XCount+x] do Height:=0;
      for x:=0 to XCount-1 do with Map[(YCount-1)*XCount+x] do Height:=0;
      for y:=1 to YCount-2 do begin;
        pChar(p):=bm.ScanLine[y-1];
        for x:=0 to XCount-1 do with Map[y*XCount+x] do
          if (x=0) or (x=XCount-1) then Height:=0
          else begin;
            Height:=p[1]; //G of RGB
            inc(pChar(p),3);
            end;
        end;
      end;
  finally
    bm.Free;
    end;
  end;

//генерация случайной карты заданных размеров с начальным значением и диапазоном ГСЧ
procedure GenerateMap(aWidth: integer= 0; aHeight: integer= 0;
                      aSeed: integer= 0; aRange: integer= 256);
var
  x, y: integer;
begin;
  if aWidth=0 then aWidth:=10000;
  if aHeight=0 then aHeight:=aWidth;
  WHCount:=aWidth * aHeight; SetLength(Order, WHCount);
  XCount:=aWidth+2;
  YCount:=aHeight+2;
  XYCount:=XCount * YCount; SetLength(Map, XYCount);
  RandSeed:=aSeed;
  for y:=0 to YCount-1 do begin;
    if (y=0) or (y=YCount-1)
    then for x:=0 to XCount-1 do with Map[y*XCount+x] do Height:=0
    else for x:=0 to XCount-1 do with Map[y*XCount+x] do
      if (x=0) or (x=XCount-1)
      then Height:=0
      else Height:=Random(aRange);
    end;
  end;

//вычисление таблицы смещений для перехода к каждому из d соседей
procedure DefineLinks(d: integer);
begin;
  Links[0]:=-1;
  Links[1]:=+1;
  case d of
    4: begin;
         Links[2]:=-XCount;
         Links[3]:=+XCount;
         end;
    6: begin;
         Links[2]:=-XCount;
         Links[3]:=+XCount+1;
         Links[4]:=-XCount+1;
         Links[5]:=+XCount;
         end;
    8: begin;
         Links[2]:=-XCount-1;
         Links[3]:=+XCount+1;
         Links[4]:=-XCount;
         Links[5]:=+XCount;
         Links[6]:=-XCount+1;
         Links[7]:=+XCount-1;
         end;
    end;
  end;

//сортировка ячеек карты по высоте
procedure SortMap;
var
  Counts: array[byte] of integer;
  h, x, y, xy, sum, cnt: integer;
begin;
  for h:=Low(Counts) to High(Counts) do Counts[h]:=0;
  for y:=1 to YCount-2 do for x:=1 to XCount-2 do inc(Counts[Map[y*XCount+x].Height]);
  sum:=0;
  for h:=Low(Counts) to High(Counts) do begin;
    cnt:=sum; sum:=sum+Counts[h]; Counts[h]:=cnt;
    end;
  for y:=1 to YCount-2 do begin;
    for x:=1 to XCount-2 do begin;
      xy:=y*XCount+x;
      h:=Map[xy].Height;
      cnt:=Counts[h]; Counts[h]:=cnt+1;
      Order[cnt]:=xy;
      end;
    end;
  end;

//процедура среза лишней воды для 4-связанных ячеек
procedure SetLevel4(xy: integer);
var
  d, xy2: integer;
  cut: byte;
begin;
  with Map[xy] do begin;
    cut:=Level;
    if Dir<high(Dir)-1 then exit; //ячейка обработана ранее
    Dir:=-1;
    end;
  d:=0;
  while true do begin;
    while d<4 do begin;
      xy2:=xy + Links[d];
      with Map[xy2] do if Level>cut then begin;
        if Height>cut then Level:=Height
        else begin;
          xy:=xy2;
          Level:=cut; Dir:=d xor 1; d:=-1;
          end;
        end;
      inc(d);
      end;
    d:=Map[xy].Dir;
    if d<0 then break;
    xy:=xy+Links[d];
    d:=d xor 1 + 1;
    end;
  end;

//процедура среза лишней воды для 6-связанных ячеек
procedure SetLevel6(xy: integer);
var
  d, ofs, xy2: integer;
  cut: byte;
begin;
  with Map[xy] do begin;
    cut:=Level;
    ofs:=Dir-(high(Dir)-1); //ofs=1 - нечетный ряд, ofs=0 - четный ряд сдвинут вправо
    if ofs<0 then exit; //ячейка обработана ранее
    Dir:=-1;
    end;
  d:=0;
  while true do begin;
    while d<6 do begin;
      xy2:=xy + Links[d]; if d>=2 then xy2:=xy2 - ofs;
      with Map[xy2] do if Level>cut then begin;
        if Height>cut then Level:=Height
        else begin;
          xy:=xy2; if d>=2 then ofs:=ofs xor 1;
          Level:=cut; Dir:=d xor 1; d:=-1;
          end;
        end;
      inc(d);
      end;
    d:=Map[xy].Dir;
    if d<0 then break;
    xy:=xy+Links[d];
    if d>=2 then begin; xy:=xy - ofs; ofs:=ofs xor 1; end;
    d:=d xor 1 + 1;
    end;
  end;

//процедура среза лишней воды для 8-связанных ячеек
procedure SetLevel8(xy: integer);
var
  d, xy2: integer;
  cut: byte;
begin;
  with Map[xy] do begin;
    cut:=Level;
    if Dir<high(Dir)-1 then exit; //ячейка обработана ранее
    Dir:=-1;
    end;
  d:=0;
  while true do begin;
    while d<8 do begin; //единственное отличие от SetLevel4, константа ускоряет код на 5%
      xy2:=xy + Links[d];
      with Map[xy2] do if Level>cut then begin;
        if Height>cut then Level:=Height
        else begin;
          xy:=xy2;
          Level:=cut; Dir:=d xor 1; d:=-1;
          end;
        end;
      inc(d);
      end;
    d:=Map[xy].Dir;
    if d<0 then break;
    xy:=xy+Links[d];
    d:=d xor 1 + 1;
    end;
  end;

//заполнение карты из aLinkCount-связанных ячеек приливом уровня aWater
function FillWater(aLinkCount, aWater: integer): int64;
var
  i, x, y, xy, MinHeight, MaxHeight: integer;
  SetLevel: TSetLevel;
begin;
  Result:=0;
  case alinkCount of
    4: SetLevel:=@SetLevel4;
    6: SetLevel:=@SetLevel6;
    8: SetLevel:=@SetLevel8;
    else exit;
    end;
  DefineLinks(aLinkCount);
  SortMap;
  MinHeight:=Map[Order[0]].Height;
  MaxHeight:=Map[Order[WHCount-1]].Height;
  for y:=0 to YCount-1 do for x:=0 to XCount-1 do with Map[y*XCount+x] do begin;
    if (y<=1) or (y>=YCount-2) or (x<=1) or (x>=XCount-2)
    then Level:=Height
    else Level:=MaxHeight;
    Dir:=(y and 1) + (high(Dir)-1); //слагаемое (y and 1) - пометка нечетных рядов, необходимая для SetLevel6
    end;
  if aWater>MaxHeight then begin;
    for i:=0 to WHCount-1 do begin;
      xy:=Order[i];
      with Map[xy] do if Level=Height then SetLevel(xy);
      end;
    for y:=1 to YCount-2 do for x:=1 to XCount-2 do with Map[y*XCount+x] do
      Result:=Result+(Level-Height);
    end
  else if aWater>MinHeight then begin;
    for i:=0 to WHCount-1 do begin;
      xy:=Order[i];
      with Map[xy] do if Level=Height then begin;
        if Height>=byte(aWater) then break;
        SetLevel(xy);
        end;
      end;
    for y:=1 to YCount-2 do for x:=1 to XCount-2 do with Map[y*XCount+x] do
      if Level<byte(aWater) then Result:=Result+(Level-Height);
    end;
  end;