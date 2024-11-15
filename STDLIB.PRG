*-- This function will search for other instances of the Spirits app 
*-- running. If one is found it is maxmized rather than allow another copy to start.

*-- Parameters: <expC>, [<expL>]
*--	expC : String that is to be used in the search on other title bars.
*--	expL : False (Default) executes everything, pass True to skip executing the QUTI command.

FUNCTION IsRun
	LPARAMETER pctitle, SkipThisStep		&&  The title bar of the Window (the title does not have to be the complete title that appears)
	
	*-- API Declarations
	DECLARE INTEGER GetActiveWindow IN Win32API
	DECLARE INTEGER GetWindow IN Win32API INTEGER hwnd, INTEGER dflag
	DECLARE INTEGER GetWindowText IN Win32API INTEGER hwnd, STRING @lptstr, INTEGER cbmax

	DECLARE SHORT IsIconic IN Win32API;
		INTEGER hwnd
	DECLARE INTEGER ShowWindow IN Win32API;
		INTEGER hwnd, INTEGER nCmdShow
	DECLARE SHORT BringWindowToTop IN Win32API;
		INTEGER hWnd
	DECLARE SHORT SetForegroundWindow IN Win32API;
		INTEGER hWnd
	LOCAL lcformcaption, lnhWnd, llicon
	
	LOCAL lnhwnd, lnnext, lldone, lctitle_bar, lcsearchfor, lntext_len, lldone

	If !SkipThisStep
		lcsearchfor = UPPER(pctitle)
		lnhwnd = GetActiveWindow()
		lRetval = lnHwnd
	
		lnnext = 2
		lldone = .F.
		lctitle_bar = ""

		DO WHILE NOT lldone
			IF NOT EMPTY(lnhwnd)
			    lctitle_bar = SPACE(200) + CHR(0)
			    lntext_len = GetWindowText(lnhwnd, @lctitle_bar, 200)
			    lctitle_bar = UPPER(LEFT(lctitle_bar, lntext_len))
			    lldone = (lcsearchfor $ lctitle_bar)
			    IF NOT lldone
			      lnhwnd = GetWindow(lnhwnd, lnnext)
			    ENDIF
			ELSE
				lldone = .T.
			ENDIF
		ENDDO
	Else
		lnHwnd = MainWindHandle
		lRetVal = MainWindHandle
	Endif
	
	IF lnhwnd > 0
		llicon = (IsIconic(lnhWnd) # 0)

		IF llicon
			*-- It's an icon, so restore it
			= ShowWindow(lnhWnd, 9)
		ENDIF

		*-- Make sure it's active.
		= BringWindowToTop(lnhWnd)
		= SetForegroundWindow(lnhWnd)

		*-- If we are not in a development environment, terminate
		*-- the instance of the program the user just tried to run.
		If !SkipThisStep
			CLOSE ALL
			QUIT
		ENDIF
	ENDIF	
RETURN lRetval

FUNCTION WriteToIni
	PARAMETERS tcField, tcValue, tcFile

	*-- Description      -  Write a specific field to a CFG file.
	*-- Samples		   -  =WriteToIni("TestEntry","100","SAMPLE.CFG")
	*-- Parameters      -  tcField - The name of the field to write to
	*-- 					tcValue - The value to be written
	*--					tcFile  - The name of the configuration file

	IF EMPTY(tcFile)
		tcFile = "SPIRITS.INI"
	ENDIF

	IF EMPTY(tcValue)
		tcValue = ""
	ENDIF

	PRIVATE ALL LIKE j*
	jlRetVal = .T.
	jnStr = LEN(tcField)
	jnH = FOPEN(tcFile)
	IF jnH > 0
		jnHH = -1
		DO WHILE jnHH < 0
			jcTemp = "S2KTemp.ini"
			jnHH = FCREATE(jcTemp)
		ENDDO
		jlFound = .F.
		DO WHILE NOT FEOF(jnH)
			jcLine = FGETS(jnH)      && Get the line
			IF NOT EMPTY(jcLine) AND UPPER(LEFT(jcLine,jnStr)) = UPPER(tcField)  && Found the right line
				jcNewStr = tcField + "=" + tcValue
				=FPUTS(jnHH,jcNewStr)
				jlFound = .T.
			ELSE
				*-- Write the line to the temp file
				=FPUTS(jnHH,jcLine)
			ENDIF
		ENDDO
		IF NOT jlFound          && Need to append the line
			jcNewStr = tcField + "=" + tcValue
			=FPUTS(jnHH,jcNewStr)
		ENDIF
		=FCLOSE(jnH)
		=FCLOSE(jnHH)
		ERASE (tcFile)
		RENAME (jcTemp) TO (tcFile)
	ELSE                        && Not able to open INI file
		jlRetVal = .F.
	ENDIF
RETURN jlRetVal

FUNCTION ReadFromIni
	PARAMETERS tcField, tcFile

	*-- Description		-  Return a specific field from a CFG file.
	*-- Samples			-  =ReadFromIni("TestEntry")
	*-- Parameters		-  tcField    - The name of the field to search for
	*--                      			tcFile     - The name of the configuration file
	*--                      			tlRetUpper - Return the value in upper case

	IF EMPTY(tcFile)
		tcFile = "SPIRITS.INI"
	ENDIF

	PRIVATE ALL LIKE j*
	jcRetVal = ""
	jnStr = LEN(tcField)
	jnH = FOPEN(tcFile)
	IF jnH > 0
		jlFound = .F.
		DO WHILE NOT FEOF(jnH) AND NOT jlFound
			jcLine = AllTrim(FGETS(jnH))        && Get the line
			IF UPPER(tcField) = UPPER(LEFT(jcLine,jnStr))  		&& Found the right line
				jnPos = AT("=",jcLine)
				IF jnPos > 0
					jlFound = .T.
					IF Right(jcLine,1) = "="
						jcRetVal = ""		&& The Data Value is Empty
					ELSE
						jcRetVal = ALLTRIM(SUBSTR(jcLine,jnPos+1))  		&& Data begins right after the "="
					ENDIF
				ENDIF
			ENDIF
		ENDDO
	ENDIF
	=FCLOSE(jnH)

	jcRetVal = ALLTRIM(UPPER(jcRetVal))
RETURN jcRetVal

FUNCTION GetBuild
	LPARAMETER cExeFile
	LOCAL cVersionInfoStructure, nBytes, nBuildInfoStartPos, nBuildInfoLength, cResult

	*-- these are the API functions with parameters from WIN32API.HLP

	DECLARE LONG GetFileVersionInfoSize IN VERSION STRING, LONG
	*--  LPTSTR  lptstrFilename,	// pointer to filename string
	*--  LPDWORD  lpdwHandle 	// pointer to variable to receive zero

	DECLARE GetFileVersionInfo IN VERSION STRING, LONG, LONG, STRING
	*--	LPTSTR  lptstrFilename,	// pointer to filename string
	*--	DWORD  dwHandle,	// ignored 
	*--	DWORD  dwLen,	// size of buffer
	*--	LPVOID  lpData 	// pointer to buffer to receive file-version info.

	*-- find out the length of the version info structure
	nBytes = GetFileVersionInfoSize(@cExeFile, 0)

	IF EMPTY(nBytes)
		cResult = ''
	ELSE
		*-- retrieve the version info structure
		cVersionInfoStructure = SPACE(nBytes)
		= GetFileVersionInfo(@cExeFile, 0, @nBytes, @cVersionInfoStructure)

		*-- extract the substring with the build number
		nBuildInfoStartPos = ATCC('FileVersion', cVersionInfoStructure) + LEN('FileVersion') +  1

		*-- build info terminated by CHR(0)
		nBuildInfoLength = AT(CHR(0), SUBSTR(cVersionInfoStructure, nBuildInfoStartPos)) - 1
		cResult = SUBSTR(cVersionInfoStructure, nBuildInfoStartPos, nBuildInfoLength)
	ENDIF
	CLEAR DLLS
	
	IF EMPTY(cResult)
		cResult = "Unknown"
	ENDIF
RETURN cResult

FUNCTION PrintCrystalReport         && Print Crystal Report using instance of ActiveX object
	PARAMETERS tcFileName, tcReportTitle, tnDestination
 
	PUBLIC loCrystal
	loCrystal = CREATEOBJECT("Crystal.CrystalReport")		&& Create Instance of Crystal Report Object
	loCrystal.ReportFileName = tcFileName					&& Set Report Filename
	loCrystal.WindowTitle = tcReportTitle						&& Set Title Name
	loCrystal.Destination = tnDestination						&& Set Output Destination
	loCrystal.WindowShowCloseBtn = .T.						&& Show Close Button
	loCrystal.WindowShowExportBtn = .F.					&& Hide Export Button
	loCrystal.WindowState = 2								&& Set Windowstate to Normal
 
	IF tnDestination = 1
		loCrystal.PrinterSelect()			&& Show Printer Dialog
	ENDIF
 
	lnResult = loCrystal.PrintReport()	&& Print Report
 
	IF lnResult # 0
		??CHR(7)
		=PlayWavFile("StopWarning")
		=MESSAGEBOX("Error Printing Crystal Report: " + tcReportTitle + CHR(13) + ;
			"Error #" + ALLTRIM(STR(lnResult)), 0 + 16, "Printing Failed")
	ENDIF
RETURN  
	
FUNCTION IsSpirits
	LPARAMETER pctitle		&&  The title bar of the Window (the title does not have to be the complete title that appears)
	
	* API Declarations
	DECLARE INTEGER GetActiveWindow IN Win32API
	DECLARE INTEGER GetWindow IN Win32API INTEGER hwnd, INTEGER dflag
	DECLARE INTEGER GetWindowText IN Win32API INTEGER hwnd, STRING @lptstr, INTEGER cbmax

	* GLG Added these 
	*
	DECLARE SHORT IsIconic IN Win32API;
		INTEGER hwnd
	DECLARE INTEGER ShowWindow IN Win32API;
		INTEGER hwnd, INTEGER nCmdShow
	DECLARE SHORT BringWindowToTop IN Win32API;
		INTEGER hWnd
	LOCAL lcformcaption, lnhWnd, llicon

	LOCAL lnhwnd, lnnext, lldone, lctitle_bar, lcsearchfor, lntext_len
	lcsearchfor = UPPER(pctitle)
	lnhwnd = GetActiveWindow()
	lnnext = 2
	lldone = .F.
	lctitle_bar = ""
	DO WHILE NOT lldone
		IF NOT EMPTY(lnhwnd)
		    lctitle_bar = SPACE(200) + CHR(0)
		    lntext_len = GetWindowText(lnhwnd, @lctitle_bar, 200)
		    lctitle_bar = UPPER(LEFT(lctitle_bar, lntext_len))
		    lldone = (lcsearchfor $ lctitle_bar)
		    IF NOT lldone
		      lnhwnd = GetWindow(lnhwnd, lnnext)
		    ENDIF
		ELSE
			lldone = .T.
		ENDIF
	ENDDO

	IF lnhwnd > 0
		??CHR(7)
		=PlayWavFile("StopWarning")
		*-- VEH 2.6.0 (Beta I) 6/06/01
		*-- WE WANT TO USE THIS FOR OTHER PROGRAMS AS WELL...
*!*			=MESSAGEBOX("This program has detected that Spirits " + pctitle +" is running on this machine." + CHR(13) + ;
*!*				"The Spirits Backroom and Cash Register cannot run simultaneously on the same machine.", 0 + 48, "Spirits 2000 Warning")
		=MESSAGEBOX("This program has detected that Spirits " + pctitle +" is running on this machine." + CHR(13) + ;
			"The Spirits " + pctitle + " and " + _SCREEN.Caption + " cannot run simultaneously on the same machine.", 0 + 48, "Spirits 2000 Warning")
		
		IF VERSION(2) = 0
			CLOSE ALL
			QUIT
		ELSE
			CANCEL
		ENDIF
	ENDIF	
RETURN lnhwnd		

FUNCTION UpdateStructures
	*-- Update Table Structures if DBFINFO.DBF exists
	IF FILE((Local_Path) + "\Dbfinfo.dbf")
		LOCAL lcAction, xAction, xTable
		* Action Types:
		*	ADD COLUMN Fieldname Fieldtype(nFieldWidth, nDecimal)
		*	ALTER COLUMN Fieldname Fieldtype(nFieldWidth, nDecimal)
		*	DROP COLUMN FieldName
		*	RENAME COLUMN FieldName1 TO FieldName2
		
		LOCAL ThisIsServer
		
		*-- VEH 2.6.0 (Beta I) 6/22/01  check the registry key instead of the ini file for machine type 
		*-- because the	register install and the server install use the same initial spirits.ini file
*!*			ThisIsServer = IIF(ReadFromIni("MasterFilesLocal") = "YES", .T., .F.)
		SET LIBRARY TO FOCUS.fll ADDI  
		*-- the above statement will not load focus.fll twice into memory but we do need to make 
		*-- sure to load it because some programs who use this prg don't load focus.fll beforehand
		ThisIsServer = ;
			IIF(UPPER(ALLT(REG_QueryValue("HKEY_LOCAL_MACHINE", "Software\Atlantic Systems\Spirits", "MachineType")))=="SERVER",.T.,.F.)
		*-- VEH 2.6.0 (Beta I) 6/22/01 end
								
		SET EXACT ON
		WAIT WINDOW "Updating Table Structures...." NOWAIT
		USE (Local_Path) + "\Dbfinfo" IN 0 
		SELECT Dbfinfo
		SET ORDER TO Sortid
		SCAN
			SCATTER MEMVAR
			xAction = ALLTRIM(m.action)
			xTable = ALLTRIM(m.table)
			
			IF NOT ThisIsServer
				IF ALLTRIM(m.table) == "POL" OR ALLTRIM(m.table) == "POLS" OR ALLTRIM(m.table) == "POLX"
					LOOP
				ENDIF
			ENDIF
			
			USE (Local_Path) + "\Data\" + ALLTRIM(m.table) IN 0 ALIAS CurTable EXCL
			SELECT CurTable
			DELETE TAG ALL OF &xTable
			=AFIELDS(laFieldList)
			DO CASE
				CASE xAction = "ADD"
					IF ASCAN(laFieldList, ALLTRIM(m.field1)) = 0
						IF ALLTRIM(m.decimal) = ""
							lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " ADD COLUMN " + ALLTRIM(m.field1) + " " + ;
								m.type + "(" + ALLTRIM(m.width) + ")"
						ELSE
							lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " ADD COLUMN " + ALLTRIM(m.field1) + " " + ;
								m.type + "(" + ALLTRIM(m.width) + "," + ALLTRIM(m.decimal) + ")"
						ENDIF						
						&lcAction
					ENDIF
										
				CASE xAction = "ALTER"
					IF ASCAN(laFieldList, ALLTRIM(m.field1)) # 0
						IF ALLTRIM(m.decimal) = ""
							lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " ALTER COLUMN " + ALLTRIM(m.field1) + " " + ;
								m.type + "(" + ALLTRIM(m.width) + ")"
						ELSE
							lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " ALTER COLUMN " + ALLTRIM(m.field1) + " " + ;
								m.type + "(" + ALLTRIM(m.width) + "," + ALLTRIM(m.decimal) + ")"
						ENDIF						
						&lcAction
					Else
						*- rdw 2.5.3 11/20/00 -- Adding Else clause. If dbfinfo calls for an alteration and the field does
						*- rdw 2.5.3 11/20/00 -- does not yet exist it needs to be added. (Used to allow users to 
						*- rdw 2.5.3 11/20/00 -- install over older version without having to isntall all releases.
						*- rdw 2.5.3 11/20/00 -- AS LONG AS DBINFO CONTAINS ALL NECESSARY FIELDS)
						IF ALLTRIM(m.decimal) = ""
							lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " ADD COLUMN " + ALLTRIM(m.field1) + " " + ;
								m.type + "(" + ALLTRIM(m.width) + ")"
						ELSE
							lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " ADD COLUMN " + ALLTRIM(m.field1) + " " + ;
								m.type + "(" + ALLTRIM(m.width) + "," + ALLTRIM(m.decimal) + ")"
						ENDIF						
						&lcAction
						*- rdw 2.5.3 11/20/00 -- END
					ENDIF
											
				CASE xAction = "DROP"
					IF ASCAN(laFieldList, ALLTRIM(m.field1)) # 0
						lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " DROP COLUMN " + ALLTRIM(m.field1)
						&lcAction						
					ENDIF
								
				CASE xAction = "RENAME"
					*- rdw 2.5.3 11/20/00 -- Field1 is the old name, field2 is the new name.
					*- rdw 2.5.3 11/20/00 -- Field2 may not allready exist!
					IF ASCAN(laFieldList, ALLTRIM(m.field1)) # 0 AND ASCAN(laFieldList, ALLTRIM(m.field2)) = 0
						lcAction = "ALTER TABLE " + ALLTRIM(m.table) + " RENAME COLUMN " + ALLTRIM(m.field1) + ;
							" TO " + ALLTRIM(m.field2)
						&lcAction
					ENDIF
			ENDCASE
			IF xAction = "ADD" AND !EMPTY(ALLTRIM(Dbfinfo.Default))
				SELECT CurTable
				lcAction = "REPLACE ALL " + ALLTRIM(m.field1) + " WITH " + ALLTRIM(Dbfinfo.Default)
				&lcAction
			ENDIF
			SELECT CurTable
			USE
			SELECT Dbfinfo
			REPLACE Dbfinfo.Complete WITH "YES"
		ENDSCAN
		SELECT Dbfinfo
		USE
		lcThePath = (Local_Path) + "\Dbfinfo.*"
		lcThePath = ALLTRIM(lcThePath)
		ERASE (lcThePath)
		WAIT CLEAR
	ENDIF
RETURN

FUNCTION AddTableRecords
	*--Update the Security File (PWD.DBF)
	IF FILE(Local_Path + "\Data\pwdnew.dbf")
		WAIT WINDOW "Updating Security Information...." NOWAIT
		USE (Local_Path) + "\Data\pwdnew" IN 0 ALIAS pwdnew
		USE (Local_Path) + "\Data\pwd" IN 0 ALIAS Pwd EXCL
		SELECT Pwd
		INDEX ON class+event TAG event
		SELECT pwdnew
		SCAN
			SCATTER MEMVAR MEMO
			SEEK m.class + m.event IN pwd ORDER TAG event
			IF NOT FOUND('pwd')
				m.who = "asi"
				m.tstamp = DATETIME()
				INSERT INTO pwd FROM MEMVAR
			ELSE
				SELECT Pwd
				REPLACE Question WITH m.question
				REPLACE Parent WITH m.parent
				REPLACE Key WITH m.key
				REPLACE Image WITH m.image
				REPLACE Descript WITH m.descript
				REPLACE Editable WITH m.editable
				REPLACE Who WITH "asi"
				REPLACE Tstamp WITH DATETIME()
			ENDIF
		ENDSCAN		
		USE
		lcThePath = (Local_Path) + "\Data\Pwdnew.*"
		ERASE &lcThePath
		SELECT Pwd
		USE
		RELEASE m.class, m.event, m.ask_level, m.do_level, m.question, m.scoptosale, m.who, m.tstamp
		WAIT CLEAR
	ENDIF

	*--Update the Control File (CNT.DBF)
	IF FILE(Local_Path + "\Data\cntnew.dbf")
		WAIT WINDOW "Updating Control File Information...." NOWAIT
		USE (Local_Path) + "\Data\cntnew" IN 0 ALIAS cntnew
		USE (Local_Path) + "\Data\cnt" IN 0 ALIAS Cnt EXCL
		SELECT Cnt
		INDEX ON code TAG code
		SELECT cntnew
		SCAN
			SEEK cntnew.code IN cnt ORDER TAG code
			IF NOT FOUND('cnt')
				SCATTER MEMVAR
				m.who = "asi"
				m.tstamp = DATETIME()
				INSERT INTO cnt FROM MEMVAR
			ENDIF
		ENDSCAN		
		USE
		lcThePath = (Local_Path) + "\Data\Cntnew.*"
		ERASE &lcThePath
		SELECT Cnt
		USE
		RELEASE m.crepname, m.creptype, m.cappname, m.crptname, m.rundate, m.runwho, m.class, ;
			m.level, m.gph, m.criteria, m.mquery, m.who, m.tstamp
		WAIT CLEAR
	ENDIF

	*--Update the Reports File (REPORTS.DBF)
	IF FILE(Local_Path + "\Data\repnew.dbf")
		WAIT WINDOW "Updating Report Information...." NOWAIT
		USE (Local_Path) + "\Data\repnew" IN 0 ALIAS repnew
		USE (Local_Path) + "\Data\reports" IN 0 ALIAS Reports EXCL
		SELECT Reports
		INDEX ON creptype+crepname TAG nametype
		SELECT repnew
		SCAN
			SCATTER MEMVAR MEMO
			SEEK m.creptype + m.crepname IN reports ORDER TAG nametype
			IF NOT FOUND('reports')
				m.who = "asi"
				m.tstamp = DATETIME()
				INSERT INTO reports FROM MEMVAR
			ELSE
				SELECT Reports
				REPLACE crepname WITH m.crepname
				REPLACE Parent WITH m.parent
				REPLACE Key WITH m.key
				REPLACE Image WITH m.image
				REPLACE Descript WITH m.descript
				REPLACE Editable WITH m.editable
				REPLACE Who WITH "asi"
				REPLACE Tstamp WITH DATETIME()
			ENDIF
		ENDSCAN		
		USE
		lcThePath = (Local_Path) + "\Data\Repnew.*"
		ERASE &lcThePath
		SELECT Reports
		USE
		RELEASE m.crepname, m.creptype, m.cappname, m.crptname, m.rundate, m.runwho, m.class, ;
			m.level, m.gph, m.criteria, m.mquery, m.who, m.tstamp
		WAIT CLEAR
	ENDIF

	*--Update the Labels File (TCK.DBF)
	IF FILE(Local_Path + "\data\tcknew.dbf")
		WAIT WINDOW "Updating Label Definitions...." NOWAIT
		USE (Local_Path)+"\Data\tcknew" IN 0 ALIAS tcknew
		USE (Local_Path) + "\Data\tck" IN 0 ALIAS Tck EXCL
		SELECT Tck
		CALCULATE MAX(tck.torder) to nEltron FOR ALLTRIM(tprinter) == "ELTRON"
		CALCULATE MAX(tck.torder) to nBlazer FOR ALLTRIM(tprinter) == "BLAZER"
		CALCULATE MAX(tck.torder) to nLaser FOR ALLTRIM(tprinter) == "LASER"
		SELECT Tcknew
		SCAN
			SCATTER MEMVAR
			SELECT Tck
			LOCATE FOR tck.tcode = m.tcode AND tck.tname = m.tname
			IF NOT FOUND()
				DO CASE
					CASE ALLTRIM(m.tprinter) == "ELTRON"
						nEltron = nEltron + 1
						INSERT INTO tck FROM MEMVAR
						REPLACE torder WITH nEltron
					CASE ALLTRIM(m.tprinter) == "BLAZER"
						nBlazer = nBlazer + 1
						INSERT INTO tck FROM MEMVAR
						REPLACE torder WITH nBlazer
					CASE ALLTRIM(m.tprinter) == "LASER"
						nLaser = nLaser + 1
						INSERT INTO tck FROM MEMVAR
						REPLACE torder WITH nLaser
				ENDCASE
			ELSE
				REPLACE tlabel WITH m.tlabel
			ENDIF
		ENDSCAN	
		USE
		ERASE (Local_Path)+"\data\tcknew.*"
		SELECT Tck
		USE
		RELEASE m.ttype, m.tprinter, m.tcode, m.tname, m.tprinter, nEltron, nBlazer
		WAIT CLEAR
	ENDIF

	*--Update the PAID OUT account in GLA.DBF
	IF FILE(Local_Path + "\data\cnt.dbf")
		USE (Local_Path) + "\Data\cnt" IN 0 ALIAS Cnt Shared
		mCat1 = ''
		mCat2 = ''
		mGla1 = ''
		mGla2 = ''
		
		Select Cnt
		Locate For Code = "DISCCAT"
		If Found()
			mCat1 = AllTrim(Data)
		Endif
		Locate For Code = "DISCNOTX"
		If Found()
			mCat2= AllTrim(Data)
		Endif
		Use In Cnt
				
		USE (Local_Path) + "\Data\cat" IN 0 ALIAS Cat Shared
		Select Cat
		If !Empty(mCat1)		
			Locate For AllTrim(Cat) == mCat1
			If Found()
				mGla1 = Income
			Endif
		Endif

		If !Empty(mCat2)		
			Locate For AllTrim(Cat) == mCat2
			If Found()
				mGla2 = Income
			Endif
		Endif
		Use In Cat

		USE (Local_Path) + "\Data\Gla" IN 0 ALIAS Gla Shared
		Select Gla
		If !Empty(mGla1)
			Locate For GlAccount = mGla1
			If Found()
				=RLock()
				Replace Type With "G"
				UnLock
			Endif
		Endif
		
		If !Empty(mGla2)
			Locate For GlAccount = mGla2
			If Found()
				=RLock()
				Replace Type With "G"
				UnLock
			Endif
		Endif
		Use In Gla		
	Endif
RETURN

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Name.........: MkLayout(<expC1> [,<expL1>]
* Description..: Create layout .txt file describing the currently open table.
* Date.........: 08/06/98
* Programmer...: G. Gartner
* Parameters...: <expC1>	- Name of layout file to create
*             		 : <expC2>	- Type of file being output (i.e. SDF, COMMA)
* Example......: MkLayOut("C:\Temp\Emp.Txt", "SDF")	
*              : MkLayOut("Cus.Txt", "SDF")
* Notes........: This function assumes that the table to be analyzed is currently
*              : open. Modify to fit your needs.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
Function MkLayout
Parameters TxtFileName, OutputFileType
Private pnNumFields, pnLoopCntr, pcFName, pnStart, pnEnd, pnLen, paFData

Do Case
	Case OutputFileType = "SDF"
		pnNumFields = FCount()							&& Define the number of fields in the table.
		Declare paFData[pnNumFields,5]					&& Create an array the correct size.

		pnStart = 1										&& Default start position to 1
		pnEnd   = 0										&& Default end position to 0
		For pnLoopCntr = 1 To pnNumFields				&& Loop for each field in the table.
			pcFName = Field(pnLoopCntr)					&& Field Name
			pnEnd 	= pnEnd + FSize(Field(pnLoopCntr))	&& Field Ending Position
			pnLen	= FSize(Field(pnLoopCntr))				&& Field Length

			* Populate the array
			*
			paFData[pnLoopCntr,1] = pcFName
			paFData[pnLoopCntr,2] = pnStart
			paFData[pnLoopCntr,3] = pnEnd
			paFData[pnLoopCntr,4] = pnLen

			pnStart = pnEnd + 1							&& Field Starting Position
		Next

		* Create the layout file.
		*
		Set Console Off
		Set TextMerge On
		Set TextMerge To (TxtFileName)
			\File Name........: <<SubStr(TxtFileName, Rat("\",TxtFileName)+1)>>
			\Created..........: <<DateTime()>>
			\File Type........: ASCII, Fixed Length
			\Number Of Fields.: <<pnNumFields>>
			\Number Of Records: <<RecCount()>>
			\Record Length....: <<pnStart-1>>
			\====================================================================
			\      Field Name     Start     End       Length
			\====================================================================
			For pnLoopCntr = 1 To pnNumFields
				\ <<PadR(pnLoopCntr,5)>>
				\\<<PadR(paFData[pnLoopCntr,1],15)>>
				\\<<PadR(paFData[pnLoopCntr,2],10)>>
				\\<<PadR(paFData[pnLoopCntr,3],10)>>
				\\<<PadR(paFData[pnLoopCntr,4],10)>>
			Next
			\====================================================================
		Set TextMerge Off
		Set Textmerge To
		Set Console On
	
	Case OutputFileType = "COMMA" OR OutputFileType = "SPACE" OR OutputFileType = "TAB"
		* Create the layout file.
		*
		pnNumFields = FCount()							&& Define the number of fields in the table.
		Declare paExportFields[pnNumFields,4]				&& Create an array the correct size.
		=Afields(paExportFields)							&& Populate the Array
		
		Set Console Off
		Set TextMerge On
		Set TextMerge To (TxtFileName)
			\File Name........: <<SubStr(TxtFileName, Rat("\",TxtFileName)+1)>>
			\Created..........: <<DateTime()>>
			\File Type........: ASCII, Delimited by <<(OutputFileType)>>
			\Number Of Fields.: <<pnNumFields>>
			\Number Of Records: <<RecCount()>>
			\====================================================================
			\      Field Name     Type      Width       Decimals
			\====================================================================
			For pnLoopCntr = 1 To pnNumFields
				\ <<Space(5)+PadR(paExportFields(pnLoopCntr,1),10)>>
				\\<<PadL(paExportFields(pnLoopCntr,2),6)>>
				\\<<PadL(paExportFields(pnLoopCntr,3),11)>>
				\\<<PadL(paExportFields(pnLoopCntr,4),11)>>
			Next
			\====================================================================
		Set TextMerge Off
		Set Textmerge To
		Set Console On
EndCase

Return

FUNCTION GetControlValue		&& Returns the Data Value for a Specific Record in the Control File
	PARAMETERS tcControlCode, tcAlias, tcOrder, tlLock
	
	PRIVATE ALL LIKE j*
	IF PARAMETERS() < 4
		jlLock = .F.
	ELSE
		jlLock = .T.
	ENDIF
		
	jPrevFile = Select()
	jcControlCode = tcControlCode
	jcAlias = tcAlias
	jcOrder = tcOrder
	jcRetVal = ""
	SELECT (jcAlias)
	SET ORDER TO (jcOrder)
	GO TOP
	IF SEEK(jcControlCode)
		IF jlLock
			DO WHILE .T.		
				IF RLOCK()
					jcRetVal = (jcAlias) + ".Data"
					EXIT
				ELSE
					WAIT WINDOW "Record is in Use, Retrying..." NOWAIT
					LOOP
				ENDIF
			ENDDO
		ELSE
			jcRetVal = (jcAlias) + ".Data"
		ENDIF
		WAIT CLEAR
	ENDIF
	jPrevFile = AllTrim(Str(jPrevFile))
	Select &jPrevFile
RETURN &jcRetVal

FUNCTION SetControlValue		&& Replaces the Data Value for a Specific Record in the Control File
	PARAMETERS tcControlCode, tcAlias, tcOrder, tcValue
	
	PRIVATE ALL LIKE j*
	jcControlCode = tcControlCode
	jcAlias = tcAlias
	jcOrder = tcOrder
	jcValue = tcValue

	SELECT (jcAlias)
	SET ORDER TO (jcOrder)
	GO TOP
	IF SEEK(jcControlCode)
		jcRetVal = (jcAlias) + ".Data"
		IF &jcRetVal <> jcValue
			REPLACE Who WITH Emp_uid
			REPLACE Tstamp WITH DATETIME()
		ENDIF
		REPLACE &jcRetVal WITH jcValue
		=TABLEUPDATE(.T.)
		UNLOCK
	ENDIF
RETURN jcValue

FUNCTION PlayWavFile
	PARAMETERS tcWavSetting
	LOCAL cWavFile, RetVal
	
	IF ".wav" $ tcWavSetting
		cWavFile = tcWavSetting						&& i.e "c:\windows\media\mmmbeer.wav"
	ELSE
		cWavFile = ReadFromIni(tcWavSetting)		&& i.e. "SystemErrors"
	ENDIF
	
	IF !EMPTY(cWavFile)	
		RetVal = "SET BELL TO '" + cWavFile + "',0"
		&RetVal
	ENDIF
	?? CHR(7)
	SET BELL TO
RETURN

*- rdw 2.6.0(Build I) 7/5/01 -- New function to update the new POLLOG table and indicate how many records were affected for this table and for this store
*- The idea is to build a transaction log for how many records were sent/received to/from a remote store.
*- It will allow us to compare the number of records that were sent to a store for each table and how many records were actually loaded
*- at the remote store. Vice Versa, It will log how many return records the remote store created and how many of those were loaded at corporate
*- This function is called from KSISP1.EXE and KSISP2.EXE

Function TransactionLog
	Parameters inStore, inTable,  inTransaction, inRecordsAffected, bAdditive
	
	select pollog
	
	*-If we only get the the store number as a parameter we clear the table
	If parameters() = 1 Then
		? "Clearing transaction log for store # " + alltrim(str(instore))
		Update pollog set corpout = 0, corpin = 0, remoteout = 0, remotein = 0, tcorpout = {//}, tcorpin = {//}, tremotein = {//}, tremoteout = {//} ;
			where store =  instore
		return
	Endif
	If Parameters() < 5 then
		*-make sure it is false
		bAdditive = .F.
	Endif

	*-make sure we are always dealing with same 'format'
	intable = upper(inTable)

	*-First find the record in pollog
	If not Seek(bintoc(inStore,4)+alltrim(inTable), "POLLOG", "STORE") Then
		*-make sure to insert the table
		insert into pollog (store, table) values (instore, alltrim(intable))
	Endif
	
	*-Now we are on the correct record
	inTransaction = upper(alltrim(inTransaction))
	Do Case 
		Case inTransaction == "CORPOUT"
			*-ksisp1 is running for the first time creating output file. 
			If bAdditive = .T. Then
				Replace pollog.corpout with pollog.corpout + inRecordsAffected, pollog.tcorpout with datetime()
			Else
				Replace pollog.corpout with inRecordsAffected, pollog.tcorpout with datetime()
			Endif
		
		Case inTransaction == "REMOTEIN"
			*-ksisp2 is running for the first time Loading updates from corporate
			If bAdditive = .T. Then
				Replace pollog.remotein with pollog.remotein + inRecordsAffected, pollog.tremotein with datetime()
			Else
				Replace pollog.remotein with inRecordsAffected, pollog.tremotein with datetime()
			Endif
	
		Case inTransaction == "REMOTEOUT"
			*-ksisp2 is running for the second time creating return files for corporate
			If bAdditive = .T. Then
				Replace pollog.remoteout with pollog.remoteout  + inRecordsAffected, pollog.tremoteout with datetime()
			Else
				Replace pollog.remoteout with inRecordsAffected, pollog.tremoteout with datetime()
			Endif

		Case inTransaction == "CORPIN"
			*-ksisp1 is running for the second time uploading all the data from the remote store
			If bAdditive = .T. Then
				Replace pollog.corpin with pollog.corpin + inRecordsAffected, pollog.tcorpin with datetime()
			Else
				Replace pollog.corpin with inRecordsAffected, pollog.tcorpin with datetime()
			Endif
		
	EndCase

	
EndFunc

*- rdw 11/21/01 --  -- Common proc to start a transaction if we are using databases
Procedure DoBeginTransact
	If bUseDB Then
		Begin Transaction
	Endif
EndProc

Procedure DoEndTransact
	If bUseDB Then
		If txnlevel() > 0 Then
			End Transaction
		Endif
	Endif
EndProc
*- rdw 11/21/01 -- End

*-- VEH 1/02/2002 add function for determine whether status is active status of an item
**********************************************************************************
*!*	PROCEDURE: ItemActive
*!*	IN: nValue -  the status value to consider
*!*	OUT: none
*!*	RETURN: .T. if item active, .F. otherwise
*!*	DESCRIPTION: Given nValue, determine if this is an active status
*!*	Had to do this for Spr 302 where Bevmax asked that we add more status to Spirits.
*!*	Had to add status values greater than two (like status 3,4) but they were of 
*!*		discontinued status.  No longer could the code be stk.stat < 2, we have to consider
*!*		status 3 and 4
**********************************************************************************
FUNCTION ItemActive
	LPARAM nValue
	DO CASE
		CASE (nValue = 2) OR (nValue = 8) OR (nValue = 9)
			RETURN .T.
		OTHERWISE
			RETURN .F.
	ENDCASE
ENDFUNC

*-- VEH 1/02/2002 add function for retrieving items status
**********************************************************************************
*!*	PROCEDURE: ItemStatus
*!*	IN: insku - the sku of the item, instore - the store number
*!*	OUT: none
*!*	RETURN: the status of the item
*!*	DESCRIPTION: attempt to retrieve this items status for the current store,
*!*	if that doesn't work, use the price default store, if that doesn't work, 
*!*	use store 1, if that doesn't work, return stat '0'
**********************************************************************************
FUNCTION ItemStatus
	LPARAM insku, instore, instkalias
	local calias, creturn
	
	cAlias = ALIAS()
		
	IF TYPE('instkalias') = 'L' THEN
		SELECT stk
	ELSE
		SELECT (instkalias)
	ENDIF
	
	SEEK BINTOC(insku)+BINTOC(instore,4) ORDER TAG sku
	IF FOUND() THEN
		cReturn = stat
		SELECT (cAlias)
		RETURN creturn
	ENDIF
	
	SEEK BINTOC(insku)+BINTOC(VAL(gcPriceDefaultStore),4) ORDER TAG sku
	IF FOUND() THEN
		cReturn = stat
		SELECT (cAlias)
		RETURN creturn
	ENDIF

	IF gcPriceDefaultStore <> '1' THEN
		SEEK BINTOC(insku)+BINTOC(1,4) ORDER TAG sku
		IF FOUND() THEN
		cReturn = stat
		SELECT (cAlias)
		RETURN creturn
		ENDIF
	ENDIF
	
	SELECT (cAlias)
	RETURN '0'
	
ENDFUNC


*-- VEH 1/02/2002 add function for retrieving items status
**********************************************************************************
*!*	PROCEDURE: FormStkStat
*!*	IN: none
*!*	OUT: none
*!*	RETURN: the status of the item
*!*	DESCRIPTION: this function used in various forms to set filter/retrieve values on grids
**********************************************************************************
FUNCTION FormStkStat
	*-- try this store first
	SEEK BINTOC(inv.Sku)+BINTOC(VAL(gcThisStore),4) IN stk ORDER TAG sku
	IF FOUND('stk')
		RETURN stk.stat
	ENDIF

	*-- If you can't find that record, try the price default store
	SEEK BINTOC(inv.sku)+BINTOC(VAL(gcPriceDefaultStore),4) IN stk ORDER TAG sku
	IF FOUND('stk')
		RETURN stk.stat
	ENDIF

	IF gcPriceDefaultStore <> '1' THEN
		SEEK BINTOC(inv.sku)+BINTOC(1,4) IN stk ORDER TAG sku
		IF FOUND('stk')
			RETURN stk.stat
		ENDIF
	ENDIF

	*-- else return a 0 status
	RETURN '0'
ENDFUNC


*-- VEH 1/25/2002
**********************************************************************************
*!*	PROCEDURE: DeleteSkuFromTable
*!*	IN: cAlias - table alias
*!*	OUT: none
*!*	RETURN: .T. if all went well, .F. otherwise
*!*	DESCRIPTION: this function used to delete sku completely from a table per spr 306
**********************************************************************************
FUNCTION DeleteSkuFromTable
	LPARAM cAlias, nSku
	
	Wait Window "Deleting Sku from "+cAlias+" table." NOWAIT
	
	*-- open the table if its not already open
	IF NOT USED(calias) THEN
		*-- if the table doesn't exist, return .F.
		IF NOT FILE((SERVER_PATH)+'\'+cAlias+".dbf") THEN
			RETURN .F.
		ENDIF
		USE (SERVER_PATH)+'\'+cAlias IN 0 SHARED ALIAS (cAlias)
		nBuffer = 3
	ELSE
*!*			=TABLEUPDATE(0,.T.,calias)
		*-- save the buffering setting
		IF !bUseDB THEN
			nBuffer = CURSORGETPROP('BUFFERING', cAlias)
		ENDIF
	ENDIF
	
	SELECT (cAlias)
	IF !bUseDB THEN
		*-- need to set table buffering becuase we'll be updating several rows
		=CURSORSETPROP('BUFFERING',5, cAlias)	
	ENDIF
		
	IF FieldInTable(cAlias,'who') THEN
		UPDATE (cAlias) SET who = emp_uid WHERE sku = nSku
	ENDIF
	IF FieldInTable(cAlias, 'tstamp') THEN
		UPDATE (cAlias) SET tstamp = DATETIME() WHERE sku = nSku
	ENDIF
	
	DELETE FROM (cAlias) WHERE sku = nSku
	IF !bUseDB THEN
		=TABLEUPDATE(1,.T.,calias)
		*-- return to the old buffering setting
		=CURSORSETPROP('BUFFERING',nBuffer, cAlias)	
	ENDIF
	RETURN .T.
ENDFUNC

*-- VEH 1/25/2002
**********************************************************************************
*!*	PROCEDURE: FieldInTable
*!*	IN: cAlias - table alias, cField
*!*	OUT: none
*!*	RETURN: .T. if field cField is in table cAlias
*!*	DESCRIPTION: checks for field cField in table cAlias
**********************************************************************************
FUNCTION FieldInTable
LPARAM cAlias, cField
	nNbrFields = AFIELDS(arrFields, cAlias)	

	FOR iNbrFields = 1 TO nNbrFields
		IF UPPER(cField) == UPPER(arrFields(iNbrFields,1)) THEN
			RETURN .T.
		ENDIF
	ENDFOR
	RETURN .F.
ENDFUNC


*******************************************************************************
* FUNCTION - AppendFilesToNew
* IN: cFile1 - file to append to, cFile2 - file to append from, cFileNew - name of new file created
* OUT: none
* RETURN: -1 if error occured, 0 otherwise
* DESCRIPTION: append cFile2 to cFile1
*******************************************************************************
*-- VEH 2/04/2001 function to append one file to another
FUNCTION AppendFilesToNew
	LPARAMETERS cFile1, cFile2, cFileNew, bEraseNewFile
	LOCAL nFH1, nFH2, pnSize, nRet
	 
	IF NOT FILE(cFile1)  && Does file exist? 
		RETURN -1
	ENDIF
	IF NOT FILE(cFile2)  && Does file exist? 
		RETURN -1
	ENDIF

	IF FILE(cFileNew) THEN
		IF bEraseNewFile
			ERASE (cFileNew)
			nFH1 = FCREATE(cFileNew)	
		ELSE
			nFH1 = FOPEN(cFileNew,12)
		ENDIF
	ELSE
		nFH1 = FCREATE(cFileNew)	
	ENDIF	
	
	IF nFH1 < 1  && Check for error opening file
		RETURN -1
	ENDIF
	FCLOSE(nFH1)  && Close file

	*-- MAKE SURE THE NEW FILENAME IS UPPERCASE
	oFSO = CREATEOBJECT("Scripting.FileSystemObject")
	oFSO.MoveFile( cFileNew, UPPER(cFileNew))
	RELEASE oFSO

	nFH1 = FOPEN(cFileNew,12)
	
	pnSize = FSEEK(nFH1,0,2)  && get the file size
	n = FSEEK(nFH1, pnSize, 0) && move to end of file

	*-- APPEND FILE 1
	nFH2 = FOPEN(cFile1,12)
	IF nFH2 < 1  && Check for error opening file2
		RETURN -1
	ENDIF

	DO WHILE NOT FEOF(nFH2)
		nRet = FWRITE(nFH1, FREAD(nFH2, 1024) )
		IF nRet = 0
			EXIT
		ENDIF
	ENDDO
	FCLOSE(nFH2)  && Close file
	
	*-- APPEND FILE 2
	nFH2 = FOPEN(cFile2,12)
	IF nFH2 < 1  && Check for error opening file2
		RETURN -1
	ENDIF

	DO WHILE NOT FEOF(nFH2)
		nRet = FWRITE(nFH1, FREAD(nFH2, 1024) )
		IF nRet = 0
			EXIT
		ENDIF
	ENDDO

	FCLOSE(nFH1)  && Close file
	FCLOSE(nFH2)  && Close file
	RETURN 0
ENDFUNC

*******************************************************************************
* FUNCTION - SkuToDeleteCursor
* IN: nSku - sku to investigate
* OUT: cFullPath - full path to table created by function where the sku was found
* RETURN: -1 if error occured, 1 if the sku was found, 0 if the sku was not found
* DESCRIPTION: used to report on sku's that are up for deletion but might be used
*		in important places.
*		So, search for the sku in active PO's, active sale lists, counted lists
*		or active customer orders.  Create a temporary table and pass the full path to 
*		back via the cTablePath parameters (note you must use '@' when passing the 
*		cTablePath parameter to this function 
* assume poh, pod, sll, slh, hnd, odd, ohd tables are open
* remember to delete this table (use the cFullPath paramter)
* Example Call: nReturn = SkuToDeleteCursor(1234,@cPath)
*******************************************************************************
FUNCTION SkuToDeleteCursor
LPARAMETER nSku, cTablePath
	cTablePath = "c:\temp\sku2del.dbf"
	CREATE TABLE (cTablePath) FREE (sku I, desc C(60), where C(60), table C(10), ;
		listname C(60), status C(10))
	cx = SET('NEAR')
	SET NEAR ON
	IF SEEK(BINTOC(nSku), 'inv', 'sku') THEN
	ELSE
		cTablePath = ''
		SET NEAR &cx
		RETURN -1
	ENDIF
	
	IF NOT USED('hnd') THEN
		USE (SERVER_PATH+'\data\hnd') IN 0 SHARED
	ENDIF
	IF NOT USED('pod') THEN
		USE (SERVER_PATH+'\data\pod') IN 0 SHARED
	ENDIF
	IF NOT USED('sll') THEN
		USE (SERVER_PATH+'\data\sll') IN 0 SHARED
	ENDIF
	IF NOT USED('odd') THEN
		USE (SERVER_PATH+'\data\hnd') IN 0 SHARED
	ENDIF
	
	SELECT pod
	SET ORDER TO sku
	SEEK BINTOC(nSku,4)+'5' IN pod ORDER TAG sku
	DO WHILE pod.sku=nSku 
		INSERT INTO sku2del (sku, desc, where, table, listname, status) VALUES ;
			(nSku, ALLT(inv.name), 'Purchase Order', 'pod', ALLT(STR(pod.order,10,0)), pod.status)
		SKIP 1 IN pod
	ENDDO
	
	SELECT sll
	SET ORDER TO SKU
	SEEK BINTOC(nSku,4) IN sll ORDER TAG sku
	DO WHILE sll.sku=nSku 
		IF sll.status = 'A' THEN
			INSERT INTO sku2del (sku, desc, where, table, listname, status) VALUES ;
				(nSku, ALLT(inv.name), 'Sale Lists', 'sll', sll.listname, sll.status)
		ENDIF
		SKIP 1 IN sll
	ENDDO
	
	SELECT hnd
	SET ORDER TO sku
	SEEK BINTOC(nSku,4) ORDER TAG sku
	DO WHILE hnd.sku = nSku
		INSERT INTO sku2del (sku, desc, where, table, listname, status) VALUES ;
			(nSku, ALLT(inv.name), 'Counting Lists', 'hnd', hnd.ListName, '')			
		SKIP 1 IN hnd
		
	ENDDO

	SELECT odd
	SET ORDER TO sku
	SEEK BINTOC(nSku,4)+'5' ORDER TAG sku
	DO WHILE odd.sku = nSku
		INSERT INTO sku2del (sku, desc, where, table, listname, status) VALUES ;
			(nSku, ALLT(inv.name), 'Customer Orders', 'odd', ALLT(STR(odd.order,10,0)), odd.status)			
		SKIP 1 IN odd		
	ENDDO
	
	SET NEAR &cx
	IF RECCOUNT('sku2del') > 0 THEN
		USE IN sku2del
		RETURN 1
	ELSE
		USE IN sku2del
		RETURN 0
	ENDIF
ENDFUNC