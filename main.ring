# The Main File

load "lib.ring"

import RingORM

COLUMN_NAME = 4
COLUMN_TYPE = 6
COLUMN_WIDTH = 7
COLUMN_DECIMAL = 9


func Main
	cDB = "vir2022"	
	cConnStr = "Driver={ODBC Driver 17 for SQL Server};Server=PC-IRWIN\SQLIRWIN;Database=" + cDB + ";Uid=sa;Pwd=Subifor2012"		
	cTable = "g10cav22"	
	// testReference(cConnStr, cTable)
	aData = query()
	? aData[1][:serie]

func testReference tcConnStr, tcTable
	c = clock()
	h = odbc_init()
	odbc_connect(h, tcConnStr)
	odbc_execute(h, "select * from " + tcTable)
	nCols = odbc_colcount(h)
	while odbc_fetch(h)
		for i = 1 to nCols
			vData = odbc_getdata(h, i)
		next
	end
	odbc_disconnect(h)
	? "Time: " + (clock() - c) / clockspersecond() + " seconds"
	

func testRingORM
		oDBManager = new DBManager	
		cDB = "vir2022"	
		cTable = "g10cav22"
		cConnStr = "Driver={ODBC Driver 17 for SQL Server};Server=PC-IRWIN\SQLIRWIN;Database=" + cDB + ";Uid=sa;Pwd=Subifor2012"	
		// test(cConnStr)
		
		oDBManager.connect(cConnStr)
		oTable = oDBManager.open(cTable)
		? len(oTable)
		/*
		cDate = substr(left(oSocios[1].FECHA, 10), "-", "/")
		cYear = left(cDate, 4)
		cDay = right(cDate, 2)
		cMonth = substr(cDate, 6, 2)
		cNewDate = print2str("#{cDay}/#{cMonth}/#{cYear}")
		? addDays(cNewDate, 1)
		? "Listo"
		*/
		

func test(tcConnStr)
		h = odbc_init()
		odbc_connect(h, tcConnStr)
		odbc_execute(h, "use vir2022")
		odbc_columns(h, "g10cav22")
		nCol = odbc_colcount(h)
		while odbc_fetch(h)			
			? odbc_getdata(h, COLUMN_NAME)
			? odbc_getdata(h, COLUMN_TYPE)
			? odbc_getdata(h, COLUMN_WIDTH)
			? odbc_getdata(h, COLUMN_DECIMAL)
		end
		odbc_disconnect(h)

func query
	c = clock()
	h = odbc_init()
	cConnStr = "Driver={ODBC Driver 17 for SQL Server};Server=PC-IRWIN\SQLIRWIN;Database=vir2022;Uid=sa;Pwd=Subifor2012"
	odbc_connect(h, cConnStr)
	odbc_execute(h, "use vir2022")

	# ----> get table fields
	odbc_columns(h, "g10cav22")
	nCols = odbc_colcount(h)
	aFields = []	
	while odbc_fetch(h)
		add(aFields, odbc_getdata(h, 4))
	end
	# <---- get table fields

	# ----> fill table data
	aTable = []
	odbc_execute(h, "select top(1) * from g10cav22")
	nCols = odbc_colcount(h)
	while odbc_fetch(h)
		aRow = []
		for i = 1 to nCols
			aRow[aFields[i]] = odbc_getdata(h, i)
		next
		add(aTable, aRow)
	end
	# <---- fill table data

	odbc_disconnect(h)
	? "Time: " + (clock() - c) / clockspersecond() + " seconds"

	return aTable
