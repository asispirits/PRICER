
PARAMETERS lcAutoRun
*-- Notes on parameters
*-- AUTO starts program 
*-- AUTO2 starts program without login, and launches notepad with REINDEX.LOG results file
*- rdw 2.5.3 12/08/00 -- AUTO3 is same as AUTO but exits when done. This is used upon installation

IF EMPTY(lcAutoRun)
	lcAutoRun = ""
ENDIF

*lcAutoRun ="AUTO"
_SCREEN.WindowState = 2
_SCREEN.Fontname = "Courier New"
_SCREEN.Fontbold = .T.
_SCREEN.Fontsize = 10
_SCREEN.Visible = .F.
_SCREEN.Refresh()

SET HOURS TO 12
SET EXCLUSIVE OFF
SET MULTILOCKS ON
SET STATUS BAR OFF
SET DELETED OFF
SET TALK OFF
SET SYSMENU OFF
SET CENTURY ON
SET CENTURY TO 19 ROLLOVER 60
SET REPROCESS TO 1 SECOND  && file locks will be attempted for 1 second
SET NEAR OFF
SET EXACT OFF
SET CONFIRM ON
SET SAFETY OFF
SET TALK OFF
SET LOCK OFF	&& do not lock files during CALCULATE, SUM, ect.
SET DELETED ON
SET MEMOWIDTH TO 255
SET NOTIFY OFF
SET BELL ON
SET INTENSITY OFF
SET ESCAPE OFF
SET REFRESH TO 5,5	 && grids are refreshed every 5 seconds, network buffers also

=setup()

 *SET PROCEDURE TO Stdlib.prg ADDITIVE
*SET HELP TO Spirits.hlp

 PUBLIC  Tools_Path
*PUBLIC Local_Path, Server_Path, Tools_Path
*Local_Path = ReadFromIni("LocalPath")
*Server_Path = ReadFromIni("ServerPath")

*-- VEH 10/11/2001 open up database on local and server
*!*	If FILE((Server_Path)+"\data\S2K.DBC") Then
*!*		ServerDB = ALLT(Server_Path) + "\data\S2K"
*!*		OPEN DATABASE (ServerDB) SHARED
*!*		? 'Opened database ' + (ServerDB)
*!*		bUseDB = .T.
*!*	ENDIF
*!*	If FILE((Local_Path)+"\data\S2K.DBC") Then
*!*		LocalDB = ALLT(Local_Path) + "\data\S2K"
*!*		OPEN DATABASE (LocalDB) SHARED
*!*		? 'Opened database ' + (LocalDB)
*!*		bUseDB = .T.
*!*	ENDIF
*-- VEH 10/11/2001 end

*-- Set up the path so we can instantiate the application object
SET DEFAULT TO (Local_Path)
*SET PATH TO PROGS, FORMS, LIBS, MENUS, DATA, REPORTS, BITMAPS, MAP,

SET PATH TO PROGS, FORMS, LIBS, MENUS, DATA, REPORTS, BITMAPS, PROJECTS,projects\PRICER
*SET PATH TO PROGS, FORMS, LIBS, MENUS, DATA, REPORTS, BITMAPS, PROJECTS

Tools_Path = (Local_Path) + "\FOXTOOLS.FLL"
SET LIBRARY TO &Tools_Path ADDITIVE	&& FoxPro Function Library

PUBLIC KS_error
KS_error = ""   && 
ON ERROR DO KSerror WITH ERROR( ), MESSAGE( ), MESSAGE(1), PROGRAM( ), LINENO( )
on error

*IF FILE("c:\temp\whobuys.dbf")
*	ERASE "c:\temp\whobuys.dbf"
*ENDIF		

DO FORM PRICER
READ EVENTS

*-- Reset enviroment	
RELEASE WINDOWS ALL
CLOSE ALL
IF VERSION(2) = 0		&& The EXE is running
   QUIT
ENDIF
CLEAR ALL  && Releases from memory all variables and arrays and the definitions of all user-defined menu bars, menus, and windows
SET STATUS BAR ON
SET LIBRARY TO
ON ERROR
ON KEY
CLEAR
SET SYSMENU TO DEFAULT
SET HELP TO
SET SYSMENU ON
_SCREEN.Closable = .T.
_SCREEN.Caption = "Microsoft Visual FoxPro"
_SCREEN.Icon = ""
_SCREEN.Picture = ""
_SCREEN.BackColor = RGB(255, 255, 255)
CLEAR ALL
RELEASE ALL
RETURN

*-- End of main program (map)



ON ERROR DO KSerror WITH ERROR( ), MESSAGE( ), MESSAGE(1), PROGRAM( ), LINENO( )

PROCEDURE KSerror
	PARAMETER merror, mess, mess2, mprog, mlineno, who, tstamp
	IF !USED('errors')
		USE (Server_Path)+"\DATA\errors" IN 0 SHARED
	ENDIF	
	INSERT INTO Errors (ErrNum, Message, Message2, lineNum, Program, Who, Tstamp) ;
		VALUES (merror, mess, mess2, mlineno, ;
		        mprog, IIF(TYPE('emp_uid') = "U", "", emp_uid), DATETIME())
	ACTIVATE SCREEN
	? "System Error Number : " + ALLTRIM(STR(merror))
	? "Error Message : " + mess
	? "Error Code : " + mess2
	? "Line Number : " + ALLTRIM(STR(mlineno))
	?? "  Program Name : " + mprog
	_Screen.Caption = "ERROR #"+ALLTRIM(STR(merror))
	KS_error = "ERROR "+ALLT(STR(merror))
	
	LOCAL line1, line2, line3, line4, line5, line6
	line1 = "System Error !" + CHR(13) + CHR(13)
	line2 = "Error Number : " + ALLTRIM(STR(merror)) + CHR(13)
	line3 = "Error Message : " + mess + CHR(13)
	line4 = "Error Code : " + mess2 + CHR(13)
	line5 = "Line Number : " + ALLTRIM(STR(mlineno)) + CHR(13)
	line6 = "Program Name : " + mprog
	??CHR(7)
	use && close the errors file
	RETURN .F.
ENDPROC	

PROCEDURE setup
*-- Standard stuff for all reports
	USE c:\temp\cheader IN 0 SHAR
	SELECT cheader
	GO TOP
	PUBLIC Local_Path,Server_Path,emp_name,gcCompany,gcSerial,gcVersion,gcCompany,gcStreet1, ;
		gcStreet2,gcCity,gcState,gcZip,gcPhone,gcStores,gcRegisters,gcThisStore,gcThisReg, ;
		StoreCount,emp_uid,emp_id
		
	PUBLIC gcXMLPath,gcStartStore,gcEndStore,gcStoreNum,gcStartDate,gcEndDate
	
	Local_Path		= ALLT(cheader.localpath)
	Server_Path	= ALLT(cheader.serverpath)

	emp_name		= cheader.ruser
	gcCompany		= cheader.cname
	gcSerial			= cheader.cSerial
	gcVersion		= cheader.cVersion
	gcStreet1		= cheader.cStreet1
	gcStreet2		= cheader.cStreet2
	gcCity			= cheader.cCity
	gcState			= cheader.cState
	gcZip			= cheader.cZip
	gcPhone	   	= cheader.cPhone	
	gcStores		= cheader.cStores
	gcRegisters		= cheader.cRegisters
	gcThisStore		= cheader.cThisStore
	gcThisReg		= cheader.cThisReg
	emp_uid		= cheader.cEmpuid
	emp_id			= cheader.iEmpid

	*-- Setup for this report
	=Openfiles()
*	StoreCount  = RECCOUNT('Str')

*!*		SELECT Reports
*!*		PUBLIC lcSPONum, lcEPONum, lcSLiqType, lcELiqType, lcReptTitle, lcQueryName,lcListnum, ;
*!*		       lcSStore, lcEStore, dmsg, lcValueOption, lcSkipInactive, lcVariance, ;
*!*		       lcLastPurchased,lcStartLevel,lcEndLevel,lcSname,lcEname,poh_status, ;
*!*		       gcAppName, gcRptName, gcClass, gcLevel,gcGph,lcSkipOuts,lcSkipNegs 
*!*		STORE "" TO lcSLiqType, lcELiqType, lcReptTitle, lcQueryName, dmsg,lcSname,lcEname,poh_status,lcListnum
*!*		STORE ALLT(gcThisStore) TO lcSStore,lcEStore
*!*		
*!*		gcAppName		= reports.cappname 
*!*		gcRptName		= reports.crptname
*!*		gcClass			= reports.class
*!*		gcLevel			= reports.level
*!*		gcGph			= reports.gph
*!*		lcReptTitle		= reports.crepname

 	 

ENDPROC


PROCEDURE openfiles
	USE (Server_Path)+"\data\inv" IN 0 SHARED
	USE (Server_Path)+"\data\upc" IN 0 SHARED
	USE (Server_Path)+"\data\prc" IN 0 SHARED
	USE (Server_Path)+"\data\typ" IN 0 SHARED
	USE (Server_Path)+"\data\stk" IN 0 SHARED
	USE (Server_Path)+"\data\esl" IN 0 SHARED
ENDPROC	

FUNCTION invcases
	LPARAMETERS tnQty,tnUnitCase,tnPack
	LOCAL cCases, flt, fll, bot,inv_pack
	IF tnQty = 0
		RETURN ""
	ENDIF
	cCases = ""
	inv_pack = tnPack
	IF inv_pack < 1
		inv_pack = 1
	ENDIF
	IF !tnUnitCase
		RETURN ALLT(STR(tnQty))
	ENDIF
	flt = INT(tnQty/inv_pack)
	fll = tnQty -flt*inv_pack
	bot = ALLTRIM(STR(fll))
	DO CASE
		CASE ABS(flt) < 10000 AND flt >= 0
			cCases = STR(flt,4)+":"+bot
		CASE ABS(flt) < 100000 AND fll < 100
			cCases = STR(flt,5)+":"+bot
		CASE ABS(flt) < 1000000 AND fll < 10
			cCases = STR(flt,6)+":"+bot
		OTHERWISE
			cCases = STR(flt,7)+":"
	ENDCASE
	RETURN ALLTRIM(cCases)
ENDFUNC