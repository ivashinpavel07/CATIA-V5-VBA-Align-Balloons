Attribute VB_Name = "ModuleAlignBalloons"
Sub CATMain()

    Dim OdjUserFormAlignBalloons As UserFormAlignBalloons
    
    Set OdjUserFormAlignBalloons = VBA.UserForms.Add(UserFormAlignBalloons.Name)

    OdjUserFormAlignBalloons.Show vbModeless

End Sub

