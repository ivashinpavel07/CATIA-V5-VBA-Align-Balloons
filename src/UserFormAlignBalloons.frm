VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} UserFormAlignBalloons 
   Caption         =   "Выравнивание Balloon без пересечения его указателей (leader)"
   ClientHeight    =   6420
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   6165
   OleObjectBlob   =   "UserFormAlignBalloons.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "UserFormAlignBalloons"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Private Type ComplexVector
    RealPart As Double
    ImaginaryPart As Double
End Type

Private Sub CommandButtonGetCoordinatesLine_Click()
       
    ' Объявление переменных
    Dim DrwDoc As DrawingDocument
    Dim CurLine As Line2D
    Dim point2D1
    Dim point2D2
    Dim CurSelection
    Dim inpsel(0 To 0)
    Dim XY1(0 To 1)
    Dim XY2(0 To 1)
    
    ' Проверка выделения линии
    Set DrwDoc = CATIA.ActiveDocument
    Set CurSelection = DrwDoc.Selection
    If CurSelection.Count = 0 Then
        MsgBox "Линия не выделена. Пожалуйста, выделите линию для извлечения ее координат."
        Exit Sub
    End If
    
    ' Проверка типа выделенного объекта
    If TypeName(CurSelection.Item(1).Value) <> "Line2D" Then
        MsgBox "Выделенный объект не является линией. Пожалуйста, выделите линию для извлечения ее координат."
        Exit Sub
    End If
    
    ' Получение выделенной линии 2D
    Set CurLine = CurSelection.Item(1).Value
    
    ' Получение данных
    Set point2D1 = CurLine.StartPoint
    Set point2D2 = CurLine.EndPoint
    point2D1.GetCoordinates XY1
    point2D2.GetCoordinates XY2
    
    ' Вывод данных
    Me.TextBoxCoordinatesLineX1 = Format(XY1(0), "0.000")
    Me.TextBoxCoordinatesLineY1 = Format(XY1(1), "0.000")
    Me.TextBoxCoordinatesLineX2 = Format(XY2(0), "0.000")
    Me.TextBoxCoordinatesLineY2 = Format(XY2(1), "0.000")
    
End Sub


Private Sub CommandButtonAlignTextsWithLeaders_Click()
   
    Dim DrwDoc As DrawingDocument
    Set DrwDoc = CATIA.ActiveDocument
    Dim SelTexts As Collection
    Set SelTexts = New Collection
    
    Dim Selection 'As Selection
    Set Selection = DrwDoc.Selection
    
    Dim InputObjectType(0), Status
    InputObjectType(0) = "DrawingText"
    Status = Selection.SelectElement3(InputObjectType, "Необходима выделить позиции для выравнивания по линии", False, CATMultiSelTriggWhenUserValidatesSelection, False)
    If ((Status = "Cancel") Or (Status = "Undo")) Then Exit Sub
    
    ' Перебор выделенных объектов
    Dim i As Integer
    For i = 1 To DrwDoc.Selection.Count
        Dim SelObject As Object
        Set SelObject = DrwDoc.Selection.Item(i).Value
        If TypeName(SelObject) = "DrawingText" Then
            If SelObject.Leaders.Count > 0 Then
                SelTexts.Add SelObject
            End If
        End If
    Next i
    
    ' Если нет выделенных текстов с указателями
    If SelTexts.Count = 0 Then
        MsgBox "Нет выделенных текстов с указателями"
        Exit Sub
    End If
    
    ' Запрашиваем координаты начала и конца вектора у пользователя
    Dim VectorStartX As Double
    Dim VectorStartY As Double
    Dim VectorEndX As Double
    Dim VectorEndY As Double

    VectorStartX = Me.TextBoxCoordinatesLineX1
    VectorStartY = Me.TextBoxCoordinatesLineY1
    VectorEndX = Me.TextBoxCoordinatesLineX2
    VectorEndY = Me.TextBoxCoordinatesLineY2
    
    ' Определяем вектора ComplexVector по исходным данным
    Dim ComplexVectorStart As ComplexVector
    ComplexVectorStart = CreateComplexVector(VectorStartX, VectorStartY)
    Dim ComplexVectorEnd As ComplexVector
    ComplexVectorEnd = CreateComplexVector(VectorEndX, VectorEndY)
    Dim GivenComplexVector As ComplexVector
    GivenComplexVector = SubtractComplexVectors(ComplexVectorEnd, ComplexVectorStart)
    
    ' Рассчитываем шаг смещения
    Dim VectorStepSize As ComplexVector
    VectorStepSize = DivideComplexVector(GivenComplexVector, SelTexts.Count + 1)
    
    ' Определяем вектор Target для размещения текста при первом смещении на шаг
    Dim ComplexVectorTarget As ComplexVector
    ComplexVectorTarget = AddComplexVectors(ComplexVectorStart, VectorStepSize)
            
    ' Выравнивание текстов с указателями вдоль вектора
    Do While SelTexts.Count > 0

        Dim SelText As Object
        Dim SelectedIndex As Integer
        Dim MaxAngle As Double
        MaxAngle = 0 ' Начальное значение для поиска максимального угла

        ' Перебор выделенных текстов с указателями и для постоения векторов
        For i = 1 To SelTexts.Count
            Set SelText = SelTexts(i)
            Dim ColLeaders As DrawingLeaders
            Set ColLeaders = SelText.Leaders

            Dim ldrCurLeader As DrawingLeader
            Set ldrCurLeader = ColLeaders.Item(1)

            Dim AnchorX As Double
            Dim AnchorY As Double
            Call ldrCurLeader.GetPoint(1, AnchorX, AnchorY)
            
            ' Определяем вектор ComplexAnchorTargetVector
            Dim ComplexVectorAnchor As ComplexVector
            ComplexVectorAnchor = CreateComplexVector(AnchorX, AnchorY)
            Dim ComplexAnchorTargetVector As ComplexVector
            ComplexAnchorTargetVector = SubtractComplexVectors(ComplexVectorAnchor, ComplexVectorTarget)

            ' Рассчитываем угол между векторами ComplexVector и ComplexAnchorTargetVector
            Dim AngleBetweenVectors As Double
            AngleBetweenVectors = GetAngleBetweenVectors(GivenComplexVector, ComplexAnchorTargetVector)

            ' Находим максимальный угол
            If AngleBetweenVectors > MaxAngle Then
                MaxAngle = AngleBetweenVectors
                SelectedIndex = i
            End If
        Next i

        ' Переносим текст с указателем в точку смещения по действительной и мнимой части комплексного числа ComplexVectorTarget
        Set SelText = SelTexts(SelectedIndex)
        SelText.X = ComplexVectorTarget.RealPart
        SelText.Y = ComplexVectorTarget.ImaginaryPart

        ' Снимаем выделение
        SelTexts.Remove SelectedIndex

        ' Определяем вектор Target для размещения текста при смещении на следующий шаг
        ComplexVectorTarget = AddComplexVectors(ComplexVectorTarget, VectorStepSize)

    Loop
    
    MsgBox "ГОТОВО"

End Sub

' Функция для создания арккосинуса
Private Function ArcCos(A As Double) As Double
     On Error Resume Next
         If A = 1 Then
             ArcCos = 0
             Exit Function
         End If
         ArcCos = Atn(-A / Sqr(-A * A + 1)) + 2 * Atn(1)
     On Error GoTo 0
 End Function

' Функция для определения угла между векторами
Private Function GetAngleBetweenVectors(ComplexVector1 As ComplexVector, ComplexVector2 As ComplexVector) As Double
    Dim dotProduct As Double
    dotProduct = ComplexVector1.RealPart * ComplexVector2.RealPart + ComplexVector1.ImaginaryPart * ComplexVector2.ImaginaryPart
    
    Dim magnitude1 As Double
    magnitude1 = Sqr(ComplexVector1.RealPart ^ 2 + ComplexVector1.ImaginaryPart ^ 2)
    
    Dim magnitude2 As Double
    magnitude2 = Sqr(ComplexVector2.RealPart ^ 2 + ComplexVector2.ImaginaryPart ^ 2)
    
    ' Избегаем деления на ноль
    If magnitude1 * magnitude2 = 0 Then
        GetAngleBetweenVectors = 0
    Else
        GetAngleBetweenVectors = ArcCos(dotProduct / (magnitude1 * magnitude2))
    End If
End Function

' Функция для создания комплексного вектора
Private Function CreateComplexVector(RealPart As Double, ImaginaryPart As Double) As ComplexVector
    Dim ComplexVector As ComplexVector
    ComplexVector.RealPart = RealPart
    ComplexVector.ImaginaryPart = ImaginaryPart
    CreateComplexVector = ComplexVector
End Function

' Функция для сложения комплексных векторов
Private Function AddComplexVectors(ComplexVector1 As ComplexVector, ComplexVector2 As ComplexVector) As ComplexVector
    Dim ResultVector As ComplexVector
    ResultVector.RealPart = ComplexVector1.RealPart + ComplexVector2.RealPart
    ResultVector.ImaginaryPart = ComplexVector1.ImaginaryPart + ComplexVector2.ImaginaryPart
    AddComplexVectors = ResultVector
End Function

' Функция для вычитания комплексных векторов
Private Function SubtractComplexVectors(ComplexVector1 As ComplexVector, ComplexVector2 As ComplexVector) As ComplexVector
    Dim ResultVector As ComplexVector
    ResultVector.RealPart = ComplexVector1.RealPart - ComplexVector2.RealPart
    ResultVector.ImaginaryPart = ComplexVector1.ImaginaryPart - ComplexVector2.ImaginaryPart
    SubtractComplexVectors = ResultVector
End Function

' Функция для деления комплексного вектора на число
Private Function DivideComplexVector(ComplexVector As ComplexVector, Divisor As Double) As ComplexVector
    Dim ResultVector As ComplexVector
    ResultVector.RealPart = ComplexVector.RealPart / Divisor
    ResultVector.ImaginaryPart = ComplexVector.ImaginaryPart / Divisor
    DivideComplexVector = ResultVector
End Function
