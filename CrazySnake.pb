;Crazy Snake by falsam & Co
; 
; Contributor(s) : Demivec
:
;PB 5.31

EnableExplicit

Enumeration
  #MainForm
EndEnumeration

Enumeration
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
Global ScreenDefaultColor, GameDefaultColor, GameColor, TextColor, LineColor
Global SnakeDefaultHeadColor, SnakeDefaultBodyColor, SnakeHeadColor, SnakeBodyColor, SnakeOutlineColor
Global Text.s, PosX.f, PosY.f
Global Dir.s, PreviousDir.s
Global wx,wy

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
InitKeyboard()

;Setup Font
Font15 = LoadFont(#PB_Any, "System", 15)
Font20 = LoadFont(#PB_Any, "System", 20)
Font25 = LoadFont(#PB_Any, "System", 23)
Font40 = LoadFont(#PB_Any, "System", 40,#PB_Font_Bold)

;Setup Color
ScreenDefaultColor = RGB(127, 182, 127)
GameDefaultColor   = RGB(143, 188, 143)
LineColor          = RGB(210, 180, 140)
TextColor          = RGB(255, 255, 255)

;Setup Snake
SnakeDefaultHeadColor = RGB(210, 180, 140)
SnakeHeadColor        = SnakeDefaultHeadColor

SnakeDefaultBodyColor = RGB(255, 248, 220)
SnakeBodyColor        = SnakeDefaultBodyColor
SnakeOutlineColor     = RGB(184, 134, 11)

;Setup Layer Effect
LayerEffectFG = CreateImage(#PB_Any, 400, 400, 32, #PB_Image_Transparent)
LayerEffectBG = CreateImage(#PB_Any, 400, 400, 32, #PB_Image_Transparent)
LayerMessage  = CreateImage(#PB_Any, 400, 400, 32, #PB_Image_Transparent)

;Screen
OpenWindow(#MainForm, 0, 0, 600, 600, "Crazy Snake", #PB_Window_SystemMenu|#PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(0), 0, 0, 600, 600)

;Create Game
Game = CreateSprite(#PB_Any, 400, 400)
TimeOut = 200

Repeat
  WX = WindowX(#MainForm, #PB_Window_InnerCoordinate)
  WY= WindowY(#MainForm, #PB_Window_InnerCoordinate)
  Repeat
    Event = WindowEvent()
    
    Select Event   
      Case #PB_Event_CloseWindow
        End
    EndSelect 
  Until Event=0
  
  FlipBuffers()
  ClearScreen(RGB(220, 220, 220))
  
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
      dir = "D"
      
      TargetCreate = #True
      
      SnakeHeadColor = SnakeDefaultHeadColor
      SnakeBodyColor = SnakeDefaultBodyColor
            
      Angle = 0 :
      ZoomX = 0 : ZoomY = 0
      PosX = 0: PosY = 0
      BounceX = 0 : BounceY = 0 : Sens = 1     
      GameColor = GameDefaultColor
      
      LayerEffectReset()
    EndIf
  EndIf
  
  If GameState = #Status_GameInPlay Or GameState = #Status_GameInPause 
    
    ;-Keyboard events
    If KeyboardPushed(#PB_Key_Left) And KLR = #True
      dir.s = "G"
    ElseIf KeyboardPushed(#PB_Key_Right) And KLR = #True
      dir.s = "D"
    ElseIf KeyboardPushed(#PB_Key_Up) And KUD = #True
      dir.s = "H"
    ElseIf KeyboardPushed(#PB_Key_Down) And KUD = #True
      dir.s = "B"
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
        Case "G"
          vx = - 1 : vy = 0 : KLR = #False : KUD = #True
        Case  "D"
          vx = 1 : vy = 0 : KLR = #False : KUD = #True
        Case "H"
          vy = -1 : vx = 0 : KUD = #False : KLR = #True
        Case "B"
          vy = 1 :  vx = 0 : KUD = #False : KLR = #True
      EndSelect
      StartTime = ElapsedMilliseconds()
      FirstElement(Snakes())
      SnakePart = Snakes() ;save information for old head part
      ResetList(Snakes())
      AddElement(Snakes()) ;add a new part for the head at the front of snake
      
      If Snakes()\x = SnakePart\x + 16 * vx And Snakes()\y = SnakePart\y + 16 * vy
        vx * -1
        vy * -1
      EndIf
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
  Box(tx, ty, 16, 16, RGB(127, 255, 0))
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(tx, ty, 16, 16, RGB(0, 0, 0))
  
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
  If TileSeparation > 0
    TileSize = 400 / 5
    PosX = (600 - (TileSize * 5 + TileSeparation * (5 - 1)))/ 2
    PosY = (600 - (TileSize * 5 + TileSeparation * (5 - 1)))/ 2
    For x = 0 To 4
      For y = 0 To 4
        ClipSprite(Game, x * TileSize,  y * TileSize, TileSize, TileSize)
        RotateSprite(Game, Mod(TileRotation(x, y) + 360, 360), #PB_Absolute)
        DisplaySprite(Game, PosX + (TileSize + TileSeparation) * x, PosY + (TileSize + TileSeparation) * y)
      Next
    Next
  Else
    DisplaySprite(Game, (600 - SpriteWidth(Game))/2 + PosX, (600 - SpriteHeight(Game))/2 + PosY)
  EndIf
  
  ;- Game effect
  If GameState = #Status_GameInPlay 
    
    TimeOut - 0.001
    
    Select Score         
      Case 0 To 2 ;Bounce game ++ (KCC Idea)
        
        
        BounceX + 0.03 : BounceY + 0.03
        Angle + 0.1
        PosX = BounceX * Cos(Angle)
        PosY = BounceY * Cos(Angle)
        If Angle = 1
          Angle = 0
        EndIf
        
      Case 3 To 4 ;Bounce Game -- (KCC Idea)
        LayerEffectReset()
        If BounceX > 0
          BounceX - 0.04 : BounceY - 0.04
        EndIf
        
        Angle + 0.1
        
        PosX = BounceX * Cos(Angle)
        PosY = BounceY * Cos(Angle)
        
        If Angle = 1
          Angle = 0
        EndIf
        
      Case 5
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
        RotateSprite(Game, 0, #PB_Absolute); reset rotation to prevent jump in position during zoom changes.
        
      Case 16 To 19 ;Reduce the size of the game.
        If SpriteWidth(Game) <> 250
          ZoomSprite(Game, SpriteWidth(Game) - 1, SpriteWidth(Game) - 1)
        EndIf
        
      Case 20 To 22 ;Enlarge the size of the game.
        If SpriteWidth(Game) <> 400
          ZoomSprite(Game, SpriteWidth(Game) + 1, SpriteWidth(Game) + 1)
        EndIf
        
      Case 23 ;Move Windows (Created by Ar-s)
        ;TimeOut = 150
        If Dir <> PreviousDir
          Select Dir
            Case "G"
              ResizeWindow(#MainForm, WX-10, #PB_Ignore, #PB_Ignore, #PB_Ignore)
            Case "D"
              ResizeWindow(#MainForm, WX+10, #PB_Ignore, #PB_Ignore, #PB_Ignore)
            Case "H"
              ResizeWindow(#MainForm, #PB_Ignore, WY+10, #PB_Ignore, #PB_Ignore)
            Case "B"
              ResizeWindow(#MainForm, #PB_Ignore, WY-10, #PB_Ignore, #PB_Ignore)
          EndSelect
          
          PreviousDir = Dir
          Dir = "none"
        EndIf
        
      Case 30
        
      Case 31
        
      Case 32
        
      Case 33 To 37 ;Reduce the width of the game.
        If SpriteWidth(Game) > 250
          ZoomX=-1
          ZoomSprite(Game, SpriteWidth(Game) + ZoomX, 400)
        EndIf
        
      Case 38 To 41 ;Original Size
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

        GameColor = RGB(Random(255, 0),Random(255, 0),Random(255, 0))
        
      Case 44
        LayerEffectReset()
        
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
        GameColor = RGB(255, 255, 255)
        StartDrawing(ImageOutput(LayerEffectFG))
        DrawingMode(#PB_2DDrawing_AllChannels)      
        Circle(Random(399), Random(399), Random(100, 10), RGBA(0, 0, 255, Random(120, 30)))
        StopDrawing()
        
      Case 64 ;Reset LayerEffect
        LayerEffectReset()
        
      Case 65 To 66
        StartDrawing(ImageOutput(LayerEffectFG))
        DrawingMode(#PB_2DDrawing_AllChannels)
        LineXY(Random(399), Random(399), Random(399), Random(399), RGBA(Random(255), Random(255), Random(255), Random(255)))
        StopDrawing()
        
      Case 67 ;Reset LayerEffect
        LayerEffectReset()
        
      Default ; Fastest speed
        GameColor = GameDefaultColor
        
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
    Box(0, 0, 600, 600, ScreenDefaultColor)
    
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
