load "odbclib.ring"


Package RingORM

	# DBManager
	class DBManager			
		cConnStr = ""
		oProvider = ""

		func connect(tcConnStr)			
			cConnStr = tcConnStr
			h = _getConnection()
			_loadProvider()
			_getTables()
			odbc_disconnect(h)
		

		func open(tcTable)		
			if find(aTables, lower(tcTable)) = 0
				raise(print2str("Table not found: #{tcTable}"))
			ok
			cConnectionString = cConnStr
			cTableName = tcTable
			cDatabase = this.cDatabase
			cResult = ""
			aDataSet = []
			cScript = 
			`		
				# Column information
				COLUMN_NAME = 4
				COLUMN_TYPE = 6
				COLUMN_WIDTH = 7
				COLUMN_DECIMAL = 9		

				h = odbc_init()
				odbc_connect(h, cConnectionString)
				odbc_execute(h, "use " + cDatabase)				

				# ----> Get all table fields				
				aFields = []
				odbc_columns(h, cTableName)
				nCol = odbc_colcount(h)


				cClassScript = "class Model" + nl

				while odbc_fetch(h)
					aInfo = [
						:NAME = lower(odbc_getdata(h, COLUMN_NAME)),
						:TYPE = odbc_getdata(h, COLUMN_TYPE),
						:WIDTH = odbc_getdata(h, COLUMN_WIDTH),
						:DECIMAL = odbc_getdata(h, COLUMN_DECIMAL)
					]
					cClassScript += aInfo[:NAME] + nl
					add(aFields, aInfo)
				end
				eval(cClassScript)
				# <---- Get all table fields

				# ----> Create the instance
				oInstance = new Model
				# <---- Create the instance

				# ----> Query all rows from table
				cQuery = "SELECT TOP(25) * FROM " + cTableName
				odbc_execute(h, cQuery)
				nCols = len(aFields)
				while odbc_fetch(h)
					for i = 1 to nCols
						vData = _convertData(aFields[i], odbc_getdata(h, i))
						eval("oInstance." + aFields[i][:NAME] + " = vData")
					next
					add(aDataSet, oInstance)
				end
				# <---- Query all rows from table
				odbc_disconnect(h)
				# ----> Convert the data based on the type.
				func _convertData(taInfo, tvData)
					cType = taInfo[:TYPE]
					switch cType
					on "numeric"					
						return number(tvData)
					on "bit"
						return tvData = "1"
					off
					return tvData
				# <---- Convert the data based on the type.
			`
			eval(cScript)
			return aDataSet	
	
		private
			cDatabase = ""
			aProviders = []
			aTables = [] # List of tables in the current connection.

			func _getTables
				cDatabase = _extractFromConnStr("database")	
				h = _getConnection()			
				odbc_execute(h, "USE " + cDatabase)
				odbc_tables(h)
				nMax = odbc_colcount(h)
				while odbc_fetch(h)
					add(aTables, lower(odbc_getdata(h, 3)))
				end	
				odbc_disconnect(h)		
		

			func _loadProvider
				load "guilib.ring" # qRegularExpression

				cPattern = "MySQL\s+ODBC\s+\d\.\d{1,2}\s+[(ANSI\s)|(Unicode)]*Driver"
				add(aProviders, [:pattern = cPattern, :name = "MySQL"])

				cPattern = "MariaDB\s+ODBC\s+\d\.\d{1,2}\s+Driver"
				add(aProviders, [:pattern = cPattern, :name = "MariaDB"])

				cPattern = "Firebird/InterBase\(r\)\s+driver"
				add(aProviders, [:pattern = cPattern, :name = "Firebird"])
				
				cPattern = "PostgreSQL\s+ANSI"
				add(aProviders, [:pattern = cPattern, :name = "PostgreSQL"])

				cPattern = "SQL\s+Server"
				add(aProviders, [:pattern = cPattern, :name = "SqlServer"])

				cPattern = "SQLite3\s+ODBC\s+Driver"
				add(aProviders, [:pattern = cPattern, :name = "SQLite3"])
				oRegEx = new qRegularExpression()
				
				for provider in aProviders
					oRegEx.setPattern(provider[:pattern])
					oMatch = oRegEx.match(cConnStr,0,0,0)
					if not oMatch.hasMatch()
						continue
					ok
					eval("oProvider = new " + provider[:name])
					break
				next

			# Extract the database name using RegEx
			func _extractFromConnStr(tcTag)
				load "guilib.ring" # qRegularExpression
				cPattern = ""
				oRegEx = new qRegularExpression()
				switch tcTag
				on "database"
					cPattern = "Database=(\w+)"
				off					
				if len(cPattern) = 0
					raise("Internal error: invalid tag.")
				ok
				oRegEx.setPattern(cPattern)
				oMatch = oRegEx.match(cConnStr,0,0,0)
				if !oMatch.hasMatch()
					raise("Internal error: the string doen't have the tag: '" + tcTag + "'")
				ok
				return oMatch.captured(1)

			func _getTableFields(tcTable)
					aFields = []					
					h = _getConnection()
					_useDatabase(h)
					odbc_columns(h, tcTable)
					nCol = odbc_colcount(h)
					while odbc_fetch(h)
						add(aFields, lower(odbc_getdata(h, 4)))
					end
					odbc_disconnect(h)

					return aFields

			func _getConnection
				h = odbc_init()				
				odbc_connect(h, cConnStr)
				return h

			func _useDataBase(tHandler)
				odbc_execute(tHandler, "use " + cDatabase)


	class Engine
		func tableExists
		func tableIndex
		func indexFilter
		func tablePrimaryKey
		func getTableFields(tcDB, tcTable)
		
		func version
			? "Version of engine"

	class MySQL from Engine
		func tableExists
		func tableIndex
		func indexFilter
		func tablePrimaryKey
		func getTableFields(tcDB, tcTable)

	class MariaDB from Engine
		func tableExists
		func tableIndex
		func indexFilter
		func tablePrimaryKey
		func getTableFields(tcDB, tcTable)

	class Firebird from Engine
		func tableExists
		func tableIndex
		func indexFilter
		func tablePrimaryKey
		func getTableFields(tcDB, tcTable)

	class PostgreSQL from Engine
		func tableExists
		func tableIndex
		func indexFilter
		func tablePrimaryKey
		func getTableFields(tcDB, tcTable)


	class SqlServer from Engine
		func tableExists
			return "
				SELECT TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES
				WHERE TABLE_CATALOG = '@DB_NAME'
				AND  TABLE_NAME = '@TBL_NAME'
			"
		func tableIndex
			Return "EXEC sp_helpindex '@TBL_NAME'"

		func indexFilter
			Return " left(trimAll(index_description), 12) == 'nonclustered'"

		func tablePrimaryKey
			

		func getTableFields(tcDB, tcTable)
			cScript = "SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = '" + tcDB + "' AND TABLE_NAME = '" + tcTable + "'"

			return cScript

	class SQLite3 from Engine
		func tableExists
		func tableIndex
		func indexFilter
		func tablePrimaryKey
		func getTableFields(tcDB, tcTable)
