; Crazy Snake by falsam & Co
; 
; Contributors coder  : Demivec
; Contributors ideas  : Ar-S, Demivec, KCC, Vera
;
; Updated             : 29 Juillet 2015
; Music               : https://soundcloud.com/mutkanto/sets/fast-stuff (Call me Crazy)
; Langage             : PureBasic version 5.31
;
; GitHub              : https://github.com/falsam/CrazySnake (Code only)
;

EnableExplicit

Enumeration
  #MainForm
EndEnumeration

Enumeration Status
  #Status_GameBeforeFirstStart
  #Status_GameInPlay
  #Status_GameEndingAnimation
  #Status_GameRestartReady
  #Status_GameInPause
EndEnumeration

Global Event
Global UpdateSquares.b
Global Vx=1, Vy=0         ;Velocity x & y
Global x1, y1, x2, y2
Global KLR.b = #True      ;Left Key & Right Key enable
Global KUD.b = #True      ;Up key & down key enable
Global n
Global GameState = #Status_GameBeforeFirstStart ;FirstStart = #True, GameOver = 0
Global TargetCreate, tx, ty
Global SquareColor
Global Score, BestScore
Global Boom.b
Global Font15, Font20, font25, font40
Global Angle.f
Global ZoomX, ZoomY, BounceX.f, BounceY.f, Sens
Global TileSeparation.f, x, y, TileSize, TileSize
Global StartTime.f, TimeOut.f
Global ScreenDefaultColor, GameDefaultColor, GameColor, TextColor, LineColor, GameOpacity
Global SnakeDefaultHeadColor, SnakeDefaultBodyColor, SnakeHeadColor, SnakeBodyColor, SnakeOutlineColor
Global TargetDefaultColor, TargetOulineColor
Global Text.s, PosX.f, PosY.f
Global Dir.s, PreviousDir.s
Global wx,wy

Global EffectX, EffectY, EffectW, EffectH
Global LayerEffectFG    ;Forground layer Effect
Global LayerEffectBG    ;Background layer Effect
Global LayerMessage     ;Message layer

Global Dim TileRotation.f(4, 4)

;Game Sprite
Global Game

;Snake
Structure Snake
  x.i
  y.i
EndStructure
Global NewList Snakes.Snake()
Global SnakePart.Snake

;Message
Global TextPause.s = "Pause"


Declare LayerEffectReset(Color = #PB_Ignore)

;Engine Init
InitSprite()
InitSound()
InitKeyboard()

;Setup Font
Font15 = LoadFont(#PB_Any, "System", 15)
Font20 = LoadFont(#PB_Any, "System", 20)
Font25 = LoadFont(#PB_Any, "System", 23)
Font40 = LoadFont(#PB_Any, "System", 40,#PB_Font_Bold)

;Setup Screen Color
ScreenDefaultColor    = RGB(215, 73, 11)
TextColor             = RGB(255, 255, 255)

;Setup Game Color
GameDefaultColor      = RGBA(116, 39, 6, 255)
LineColor             = RGBA(255, 233, 40, 255)

;Setup Snake color
SnakeDefaultHeadColor = RGBA(217, 73, 11, 255)
SnakeHeadColor        = SnakeDefaultHeadColor

SnakeDefaultBodyColor = RGBA(255, 165, 0, 255)
SnakeBodyColor        = SnakeDefaultBodyColor
SnakeOutlineColor     = RGBA(184, 134, 11, 255)

;Setup target color
TargetDefaultColor    = RGBA(255, 255, 255, 255)
TargetOulineColor     = RGBA(255, 229, 38, 255)

;Setup Layer Effect
LayerEffectFG = CreateImage(#PB_Any, 400, 400, 32, #PB_Image_Transparent)
LayerEffectBG = CreateImage(#PB_Any, 400, 400, 32, #PB_Image_Transparent)
LayerMessage  = CreateImage(#PB_Any, 400, 400, 32, #PB_Image_Transparent)

;Setup Sprite
UsePNGImageDecoder()

;Screen
OpenWindow(#MainForm, 0, 0, 600, 600, "Crazy Snake", #PB_Window_SystemMenu|#PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(0), 0, 0, 600, 600)

;Create Game
Game = CreateSprite(#PB_Any, 400, 400)
TimeOut = 200

;-Event Loop
Repeat
  
  WX = WindowX(#MainForm, #PB_Window_FrameCoordinate)
  WY= WindowY(#MainForm, #PB_Window_FrameCoordinate)  
  
  Repeat
    Event = WindowEvent()
    
    Select Event   
      Case #PB_Event_CloseWindow
        End
    EndSelect 
  Until Event=0
  
  FlipBuffers()
  ClearScreen(RGB(0, 0, 0))
  
  If ExamineKeyboard() = 0 And GameState = #Status_GameInPlay ;Lost focus
    GameState = #Status_GameInPause 
  EndIf
    
  If GameState = #Status_GameRestartReady Or GameState = #Status_GameBeforeFirstStart
    
    If KeyboardReleased(#PB_Key_Up)
      GameState = #Status_GameInPlay 
      
      ;Add 4 Squares to snake
      ClearList(Snakes())
      For n = 0 To 3
        AddElement(Snakes())
        With Snakes()
          \x = 192 - 16 * n
          \y = 192
          x1 = \x
          y1 = \y
        EndWith
      Next     
      
      ;Reset Game Setup
      StartTime.f = 0
      ClipSprite(Game, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
      RotateSprite(Game, 0, #PB_Absolute)
      ZoomSprite(Game, 400, 400)
      
      Boom = 0
      
      Score = 0
      TimeOut = 199
            
      vx = 1 : vy = 0 ;Snake starts right   
      KLR = #False    ;Left Key & Right Key disable, because of snake moving right
      KUD = #True     ;Up key & down key enable
      dir = "Right"
      
      TargetCreate = #True
      
      SnakeHeadColor = SnakeDefaultHeadColor
      SnakeBodyColor = SnakeDefaultBodyColor
            
      Angle = 0 :
      ZoomX = 0 : ZoomY = 0
      PosX = 0: PosY = 0
      BounceX = 0 : BounceY = 0 : Sens = 1     
      GameColor = GameDefaultColor
      GameOpacity = 255
      
      LayerEffectReset()
    EndIf
  EndIf
  
  If GameState = #Status_GameInPlay Or GameState = #Status_GameInPause 
    
    ;-Keyboard events
    If KeyboardPushed(#PB_Key_Left) And KLR = #True
      dir.s = "Left"
    ElseIf KeyboardPushed(#PB_Key_Right) And KLR = #True
      dir.s = "Right"
    ElseIf KeyboardPushed(#PB_Key_Up) And KUD = #True
      dir.s = "Up"
    ElseIf KeyboardPushed(#PB_Key_Down) And KUD = #True
      dir.s = "Down"
    ElseIf KeyboardReleased(#PB_Key_Space)
      If GameState = #Status_GameInPause 
        GameState = #Status_GameInPlay
      Else
        GameState = #Status_GameInPause 
      EndIf
    EndIf
    
    If GameState = #Status_GameInPause
        StartDrawing(ImageOutput(LayerMessage))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, 400, 400, RGBA(255, 255, 255, 50))    
        DrawingMode(#PB_2DDrawing_AlphaBlend)
        DrawingFont(FontID(Font40))
        
        DrawRotatedText((400-TextWidth(TextPause))/2, (400-TextHeight(TextPause))/2, TextPause, 0, RGBA(255, 255, 255, 120))
        StopDrawing()
    EndIf      

    ;- Updates the position of the snake
    If ElapsedMilliseconds() - StartTime  > TimeOut And GameState <> #Status_GameInPause
       ;-Keyboard events
      Select dir
        Case "Left"
          vx = - 1 : vy = 0 : KLR = #False : KUD = #True
        Case  "Right"
          vx = 1 : vy = 0 : KLR = #False : KUD = #True
        Case "Up"
          vy = -1 : vx = 0 : KUD = #False : KLR = #True
        Case "Down"
          vy = 1 :  vx = 0 : KUD = #False : KLR = #True
      EndSelect
      
      StartTime = ElapsedMilliseconds()
      FirstElement(Snakes())
      SnakePart = Snakes() ;save information for old head part
      ResetList(Snakes())
      AddElement(Snakes()) ;add a new part for the head at the front of snake
      
      Snakes()\x = SnakePart\x + 16 * vx
      Snakes()\y = SnakePart\y + 16 * vy
      
      SnakePart = Snakes() ;save information for new head part
      
      ;-Collide(head, target)
      If SnakePart\x = tx And SnakePart\y = ty
        TargetCreate = #True
        UpdateSquares = #True
        Score + 1
      EndIf
      
      ;-Collide(head, Body)
      While NextElement(Snakes())
        If SnakePart\x = Snakes()\x And  SnakePart\y = Snakes()\y
          Boom = #True
          Break
        EndIf
      Wend
      
      If UpdateSquares = #False
        ;Remove tail part to keep snake the same length
        LastElement(Snakes())
        DeleteElement(Snakes())
      Else
        ;Adds an element to the body of the snake, it does so by NOT removing the tail part
        UpdateSquares = #False
      EndIf
      
      n = 0
      
      ;-Create target
      While TargetCreate = #True
        tx = Random(25 - 1) * 16 ;New X
        ty = Random(25 - 1) * 16 ;New y
        
        ;Intersection with the snake ?
        TargetCreate = #False
        ForEach Snakes()
          With Snakes()
            If \x = Tx And \y = Ty
              TargetCreate = #True
              Break
            EndIf
          EndWith
        Next   
      Wend
    EndIf
  EndIf
  
  ;- Drawing Game
  
  ;0 - Draw Score 
  StartDrawing(ScreenOutput())
  Box(0, 0, 600, 600, ScreenDefaultColor)
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(Font20))
  DrawText(20, 15, "Crazy Snake", TextColor)
  DrawText(20, 50, "Speed " + Str(200 - TimeOut), TextColor)
  DrawText(450, 15, "Score " + Str(Score), TextColor)
  
  DrawingFont(FontID(Font15))
  DrawText(400, 560, "falsam (2015-2015)", TextColor)
  
  StopDrawing()
  
  ;1 - Draw GameSprite
  StartDrawing(SpriteOutput(Game))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Box(0, 0, 400, 400, GameColor)
  
  ;1.1 - Draw Grid
  Global gx
  For gx = 0 To 399 Step 16
    LineXY(gx, 0, gx, 399, LineColor)
    LineXY(0, gx, 399, gx, LineColor)
  Next 
  
  ;1.2 - Draw Grid outline
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, 400, 400, LineColor)
    
  ;1.3 - Draw background layer effect
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  DrawImage(ImageID(LayerEffectBG), 0, 0)
  
  ;1.4 - Draw Snake
  DrawingMode(#PB_2DDrawing_Default)     
  ForEach Snakes()
    With Snakes()
      Select ListIndex(Snakes())
        Case 0 ;First square
          SquareColor = SnakeHeadColor
          
        Case ListSize(Snakes()) - 1 ;Last square
          SquareColor = SnakeHeadColor
          
        Default
          SquareColor = SnakeBodyColor
      EndSelect   
      
      DrawingMode(#PB_2DDrawing_Default)     
      Box(\x, \y, 16, 16, SquareColor)
      
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(\x, \y, 16, 16, SnakeOutlineColor)     
    EndWith
  Next
  
  ;1.5 - Draw target
  DrawingMode(#PB_2DDrawing_Default)
  Box(tx, ty, 16, 16, TargetDefaultColor)
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(tx, ty, 16, 16, TargetOulineColor)
  
  ;1.6 - Draw forground LayerEffect
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  DrawImage(ImageID(LayerEffectFG), 0, 0)
  
  ;1.7 - Draw message
  If GameState = #Status_GameInPause    
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    DrawImage(ImageID(LayerMessage), 0, 0)
  EndIf
  
  StopDrawing()
    
  ;- Display game
  If GameState <> #Status_GameRestartReady And GameState <> #Status_GameBeforeFirstStart
    If TileSeparation > 0
      TileSize = 400 / 5
      PosX = (600 - (TileSize * 5 + TileSeparation * (5 - 1)))/ 2
      PosY = (600 - (TileSize * 5 + TileSeparation * (5 - 1)))/ 2
      For x = 0 To 4
        For y = 0 To 4
          ClipSprite(Game, x * TileSize,  y * TileSize, TileSize, TileSize)
          RotateSprite(Game, Mod(TileRotation(x, y) + 360, 360), #PB_Absolute)
          DisplayTransparentSprite(Game, PosX + (TileSize + TileSeparation) * x, PosY + (TileSize + TileSeparation) * y, GameOpacity)
        Next
      Next
    Else
      DisplayTransparentSprite(Game, (600 - SpriteWidth(Game))/2 + PosX, (600 - SpriteHeight(Game))/2 + PosY, GameOpacity)
    EndIf
  EndIf

  ;- Game effect
  If GameState = #Status_GameInPlay 
    
    TimeOut - 0.001 ;Speed ++
    
    Select Score         
      Case 0 To 2 ;Bounce game ++ (KCC Idea)  
        BounceX + 0.03 : BounceY + 0.03
        Angle + 0.1
        PosX = BounceX * Cos(Angle)
        PosY = BounceY * Cos(Angle)
              
      Case 3 To 4 ;Bounce Game -- (KCC Idea)
        LayerEffectReset()
        If BounceX > 0
          BounceX - 0.04 : BounceY - 0.04
          GameOpacity= Random(255,128)
        EndIf
        
        Angle + 0.1
        
        PosX = BounceX * Cos(Angle)
        PosY = BounceY * Cos(Angle)
                
      Case 5
        GameOpacity = 255
        StartDrawing(ImageOutput(LayerEffectBG))
        DrawingMode(#PB_2DDrawing_AlphaBlend)         
        DrawingFont(FontID(Font20))
        DrawRotatedText(Random(399), Random(399), "I'am Crazy", Random(360), RGBA(Random(255),Random(255),Random(255),Random(255)))
        StopDrawing()

        Angle = 0 : PosX = 0 : PosY = 0
        SnakeBodyColor = RGB(255, Random(248), 220)
        SnakeHeadColor = RGB(0, Random(248), 220)
        
      Case 6 To 9 ;Right Rotate
        LayerEffectReset()
        SnakeBodyColor = SnakeDefaultBodyColor
        SnakeHeadColor = SnakeDefaultHeadColor
        
        If Angle < 45
          Angle + 0.05
          RotateSprite(Game, 0.05, #PB_Relative) 
        EndIf
        
      Case 10 To 14 ;Left Rotate
        If Angle > 0
          Angle - 0.05
          RotateSprite(Game, -0.05, #PB_Relative)
        EndIf
        
      Case 15
        Angle = 0
        GameOpacity = 200
        RotateSprite(Game, 0, #PB_Absolute); reset rotation to prevent jump in position during zoom changes.
        
      Case 16 To 19 ;Reduce the size of the game.
        GameOpacity = 255
        If SpriteWidth(Game) <> 250
          ZoomSprite(Game, SpriteWidth(Game) - 1, SpriteWidth(Game) - 1)
        EndIf
        
      Case 20 To 22 ;Enlarge the size of the game.
        If SpriteWidth(Game) <> 400
          ZoomSprite(Game, SpriteWidth(Game) + 1, SpriteWidth(Game) + 1)
        EndIf
        
      Case 23 ;Move Windows (Created by Ar-s)
        GameOpacity= Random(255,128)
        If Dir <> PreviousDir
          Select Dir
            Case "Left"
              ResizeWindow(#MainForm, WX-10, #PB_Ignore, #PB_Ignore, #PB_Ignore)
            Case "Right"
              ResizeWindow(#MainForm, WX+10, #PB_Ignore, #PB_Ignore, #PB_Ignore)
            Case "Up"
              ResizeWindow(#MainForm, #PB_Ignore, WY+10, #PB_Ignore, #PB_Ignore)
            Case "Down"
              ResizeWindow(#MainForm, #PB_Ignore, WY-10, #PB_Ignore, #PB_Ignore)
          EndSelect
          
          PreviousDir = Dir
          Dir = "none"
        EndIf
        
      Case 24 To 32
        GameOpacity = 255
        StartDrawing(ImageOutput(LayerEffectBG))
        DrawingMode(#PB_2DDrawing_AllChannels)
        EffectX = Random(399)
        EffectY = Random(399)
        EffectW = Random(150)
        EffectH = Random(150)
        
        Box(EffectX, EffectY, EffectW, EffectH, RGBA(226, Random(205, 25), 29, 80))
        DrawingMode(#PB_2DDrawing_Outlined)
        For n = 0 To 4
          Box(EffectX+n, EffectY+n, EffectW-2*n, EffectH-2*n, RGBA(255, 255, 255, 255))
        Next
        
        StopDrawing()
                       
      Case 33 To 37 ;Reduce the width of the game.
        LayerEffectReset()
        If SpriteWidth(Game) > 250
          ZoomX=-1
          ZoomSprite(Game, SpriteWidth(Game) + ZoomX, 400)
        EndIf
        
      Case 38 To 40 ;Original Size
        If SpriteWidth(Game) <> 400
          ZoomX = 1
          If SpriteHeight(Game) <> 400
            ZoomY = 1
          Else
            ZoomY = 0
          EndIf
          
          ZoomSprite(Game, SpriteWidth(Game) + ZoomX, SpriteHeight(Game) + ZoomY)
        EndIf
        
      Case 41 To 43 ;Random color
        StartDrawing(ImageOutput(LayerEffectBG))
        DrawingMode(#PB_2DDrawing_AlphaBlend)         
        DrawingFont(FontID(Font20))
        DrawRotatedText(Random(399), Random(399), "I'am Crazy", Random(360), RGBA(Random(255),Random(255),Random(255),Random(255)))
        StopDrawing()

        GameColor = RGBA(Random(255, 0),Random(255, 0),Random(255, 0), 128)
        
      Case 44
        LayerEffectReset()
        GameColor = RGB(154, 205, 50)
        GameOpacity = 180
        
      Case 45 To 48  ;Split (Created by Demivec)
        If TileSeparation = 0
          Dim TileRotation.f(4, 4) ;reset to zeros for next stage
        EndIf
        
        If TileSeparation < 24
          TileSeparation + 0.1
        EndIf
        
      Case 49 To 52 ;Random rotate tile (Created by Demivec)
        For x = 0 To 4
          For y = 0 To 4
            If (x > 1 And x < 4 And y > 1 And y < 4) Or (TileRotation(x, y) > -35 And TileRotation(x, y) < 35)
              TileRotation(x, y) + (Random(2) - 1) * 0.5
            EndIf
          Next
        Next
        
      Case 53 To 55 ;Unrotate tiles (Created by Demivec)
        For x = 0 To 4
          For  y = 0 To 4
            If TileRotation(x, y) <> 0
              If TileRotation(x, y) < 0
                TileRotation(x, y) + 0.05
              Else
                TileRotation(x, y) - 0.05
              EndIf
            EndIf
          Next
        Next
        
      Case 56 To 58 ;Join (Created by Demivec)
        If TileSeparation > 0
          TileSeparation - 0.1
        Else
          ClipSprite(Game, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
          PosX = 0: PosY = 0
        EndIf
               
      Case 59 To 63 ;
        GameColor = GameDefaultColor
        GameOpacity = 220
        StartDrawing(ImageOutput(LayerEffectFG))
        DrawingMode(#PB_2DDrawing_AllChannels)      
        Box(Random(399), Random(399), Random(150, 10),Random(150, 10), RGBA(Random(255), Random(255), Random(255), Random(70, 10)))
        StopDrawing() 
        
      Case 64 ;Reset LayerEffect
        LayerEffectReset() 
        
      Default
        Select dir
          Case "Left" : PosX - 1
          Case "Right": PosX + 1   
          Default
            
        EndSelect
                
    EndSelect
  EndIf
  
  ;Out of bound or Game over
  If GameState = #Status_GameInPlay
    FirstElement(Snakes())
    With Snakes()
      If (\x > 384 Or \x < 0 Or \y > 384 Or \y < 0 Or Boom = #True)
        GameState = #Status_GameEndingAnimation 
      EndIf
    EndWith
  EndIf
  
  If GameState = #Status_GameEndingAnimation
    If SpriteWidth(Game) <> 10
      If TileSeparation > 0
        TileSeparation = 0
        ClipSprite(Game, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
      EndIf
        
      ZoomSprite(Game, SpriteWidth(Game)-10, SpriteWidth(Game) - 10)
    Else
      GameState = #Status_GameRestartReady 
    EndIf
  EndIf
  
  
  ;- Game Over
  If GameState = #Status_GameRestartReady Or GameState = #Status_GameBeforeFirstStart
    
    If Score > BestScore
      BestScore = Score
    EndIf
    
    StartDrawing(ScreenOutput())
    
    DrawingMode(#PB_2DDrawing_Transparent)
    
    If GameState = #Status_GameBeforeFirstStart
      DrawingFont(FontID(Font40))
      Text = "Crazy Snake"
      DrawText((600 - TextWidth(Text))/2, 100, Text, TextColor)   
    Else
      DrawingFont(FontID(Font40))
      Text = "You Died"
      DrawText((600 - TextWidth(Text))/2, 100, Text, TextColor)   
      
      DrawingFont(FontID(Font25))
      Text = "Score: " + Str(Score)
      DrawText((600 - TextWidth(Text))/2, 200, Text, TextColor)
      
      DrawingFont(FontID(Font25))
      Text = "Best Score: " + Str(BestScore)
      DrawText((600 - TextWidth(Text))/2, 300, Text, TextColor)
    EndIf
    
    Text = "Press up arrow key to start new game"
    Angle + 0.1
    PosY = 20 * Cos(Angle)
    If angle = 1
      angle = 0
    EndIf
    
    DrawingFont(FontID(Font25))
    DrawText((600 - TextWidth(Text))/2, 500 + PosY, Text, TextColor )
    
    StopDrawing()
  EndIf
  
Until KeyboardPushed(#PB_Key_Escape)

Procedure LayerEffectReset(Color = #PB_Ignore)
  If Color = #PB_Ignore
    GameColor = GameDefaultColor
  Else
    GameColor = Color
  EndIf
  
  StartDrawing(ImageOutput(LayerEffectFG))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Box(0, 0, 400, 400, RGBA(0, 0, 0, 0))
  StopDrawing()
  
  StartDrawing(ImageOutput(LayerEffectBG))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Box(0, 0, 400, 400, RGBA(0, 0, 0, 0))
  StopDrawing()
EndProcedure
