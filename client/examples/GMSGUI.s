Class MyDialog: UIFrame 
{ 
  MyDialog(Object self)  Result("\n Created #"  + self.ScriptObjectGetID().hex()) 
  ~MyDialog(Object self) Result("\n Destroyed #"+ self.ScriptObjectGetID().hex()) 
  
  TagGroup DialogTG, choCrystal,choCrystal_Items, cmdGetPACBED, MyRealField, MyIntegerField, txtOrientation_u, txtOrientation_v,txtOrientation_w,lblCrystal, lblOrientation_u, lblOrientation_v, lblOrientation_w, lblHT, lblConva, txtHT, txtConva, lblGetPACBED, lblThickness, lblConfidence, cmdCalcThickness
  image img, outimg
  string py
  
  TagGroup CreateMyDialog(Object self) 
    { 
    DialogTG = DLGCreateDialog("AutoPACBED") 
    choCrystal  = DLGCreateChoice(choCrystal_Items,0) // StringField("TiO2 rutile",20)
    choCrystal.DLGAddChoiceItemEntry("TiO2 rutile",1)
    //MyRealField    = DLGCreateRealField(10.2,10,2).DLGAnchor("East") 
    //MyIntegerField = DLGCreateIntegerField(5,10).DLGAnchor("West") 
    txtOrientation_u = DLGCreateIntegerField(0,4)
    txtOrientation_v = DLGCreateIntegerField(0,4)
    txtOrientation_w = DLGCreateIntegerField(1,4)
    cmdGetPACBED   = DLGCreatePushButton("Get PACBED pattern","GetPACBEDButton")
    lblCrystal     = DLGCreateLabel("Crystal:") 
    lblOrientation_u = DLGCreateLabel("u:")
    lblOrientation_v = DLGCreateLabel("v:")
    lblOrientation_w = DLGCreateLabel("w:") 
    lblHT		   = DLGCreateLabel("HT [kV]:").DLGAnchor("West")  
    lblConva	   = DLGCreateLabel("Conv. angle [mrad]:").DLGAnchor("West")  
    lblGetPACBED   = DLGCreateLabel("...",40).DLGIdentifier("#PACBEDName").DLGAnchor("Center")  
    txtHT          = DLGCreateRealField(80,10,2).DLGIdentifier("#HTValueInput") 
    txtConva       = DLGCreateRealField(20.8,10,2) 
    cmdCalcThickness = DLGCreatePushButton("Determine Thickness","CalcThicknessButton").DLGIdentifier("#Calc")
    dlgenabled(cmdCalcThickness,0) 
    lblThickness   = DLGCreateLabel("Thickness value: ...").DLGIdentifier("#Thickness").DLGAnchor("East") 
    lblConfidence  = DLGCreateLabel("Confidence: ...").DLGIdentifier("#Confidence").DLGAnchor("East")  
      
	TagGroup grpGetPACBED, grpGetPACBEDItems 
	grpGetPACBED = DLGCreateGroup(grpGetPACBEDItems)  
    grpGetPACBEDItems.DLGAddElement(cmdGetPACBED)   
    grpGetPACBEDItems.DLGAddElement(lblGetPACBED) 
    grpGetPACBED.DLGTableLayOut(1,2,0) 
         
    TagGroup MyGroup, MyGroupItems 
    MyGroup = DLGCreateBox("Crystal and Orientation",MyGroupItems) 
    MyGroupItems.DLGAddElement(lblCrystal) 
    MyGroupItems.DLGAddElement(choCrystal)  
    MyGroupItems.DLGAddElement(lblOrientation_u) 
    MyGroupItems.DLGAddElement(txtOrientation_u)
    MyGroupItems.DLGAddElement(lblOrientation_v) 
    MyGroupItems.DLGAddElement(txtOrientation_v) 
    MyGroupItems.DLGAddElement(lblOrientation_w)  
    MyGroupItems.DLGAddElement(txtOrientation_w)
    MyGroup.DLGTableLayOut(2,5,0) 
     
    TagGroup grpPACBED, grpPACBEDItems      
    grpPACBED = DLGCreateBox("Experimental Settings",grpPACBEDItems) 
    grpPACBEDItems.DLGAddElement(lblHT) 
    grpPACBEDItems.DLGAddElement(txtHT)  
    grpPACBEDItems.DLGAddElement(lblConva) 
    grpPACBEDItems.DLGAddElement(txtConva)  
    grpPACBED.DLGTableLayOut(2,2,0) 
    
    TagGroup grpCalcThickness, grpCalcThicknessItems      
    grpCalcThickness = DLGCreateBox("Calculate",grpCalcThicknessItems) 
    grpCalcThicknessItems.DLGAddElement(cmdCalcThickness)
    grpCalcThicknessItems.DLGAddElement(lblThickness)  
    grpCalcThicknessItems.DLGAddElement(lblConfidence) 
    grpCalcThickness.DLGTableLayOut(1,3,0) 
            
    DialogTG.DLGAddElement(grpGetPACBED)
    DialogTG.DLGAddElement(MyGroup) 
    DialogTG.DLGAddElement(grpPACBED) 
    DialogTG.DLGAddElement(grpCalcThickness) 
     
    return DialogTG 
    }   
 
  Object Init(Object self)  return self.super.Init(self.CreateMyDialog()) 
  
  TagGroup GetPACBEDButton(Object self) {
	img := GetFrontImage()
	If (!img.ImageIsValid()) Exit(0)
	self.LookUpElement("#PACBEDName").DLGTitle(""+img.GetName())
	self.SetElementIsEnabled("#Calc",1) 
	//self.LookUpElement("#PACBEDName").DLGGetElement(0).DLGLabel(img.GetName()) 
	Number sx, sy
	getsize(img,sx,sy)
	Result("\n"+ sx + "/" + sy + " " + img.GetName())
	
	taggroup imgtags=img.imagegettaggroup()
	//imgtags.taggroupopenbrowserwindow(0)
	number HTvalue
	string targettaggroup="Microscope Info:Voltage"
	if(!TagGroupDoesTagExist(imgtags,targettaggroup)){
		showalert("The taggroup : '"+targettaggroup+"' was not found.",2)
		exit(0)
	}
	imgtags.taggroupgettagasnumber(targettaggroup,HTvalue)
	HTvalue = HTvalue / 1000.0
	self.LookUpElement("#HTValueInput").DLGValue(HTvalue) 
	Result("\n"+ HTvalue)
  }
  
  TagGroup CalcThicknessButton(Object self) {
	
	number imgid = img.ImageGetID()
	number ht_entered = txtHT.DLGGetStringValue().val()*1000 //self.LookUpElement("#HTValueInput")
	
	string pyScript = "from pacbedclient import imagefromresponse, query, arrayfromID; "
	pyScript += "imagefromresponse(DM, query(arrayfromID(DM, " + imgid + "), host='localhost', port=8000,ht=" + ht_entered + ",))\n"
	ExecutePythonScriptString( pyScript, 1) // remove 1 if error 'An image with given name cannot be found'

	//number nImg = CountImages()
	//for ( number i = 0 ; i < nImg ; i ++ )
	//{
	// image img := FindImageByIndex(i)
	// result(GetLabel( img ) + " " + GetName(img))
	//}

	image r_img := GetNamedImage("pacbed:viz_r")
	image g_img := GetNamedImage("pacbed:viz_g")
	image b_img := GetNamedImage("pacbed:viz_b")

	image validation := rgb(r_img, g_img, b_img)
	validation.ShowImage()

	TagGroup sourcetags = imagegettaggroup(r_img)
	TagGroup targettags = imagegettaggroup(validation)

	taggroupcopytagsfrom(targettags,sourcetags)

	DeleteImage(r_img)
	DeleteImage(g_img)
	DeleteImage(b_img)
  }
}
Object DialogOBJ = Alloc(MyDialog).Init() 
	
DialogOBJ.Display("Test Dialog") 
//DialogOBJ.Pose()