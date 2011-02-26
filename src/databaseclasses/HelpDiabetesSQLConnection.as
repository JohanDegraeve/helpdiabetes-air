/*
 * Copyright (C) 2011  hippoandfriends
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
*/

/** The database connection for the HelpDiabetes database in a static constant variable.
* The constructor will also try to open the database in an asynchronous mode, and if it's not existing yet, it will be created and the foodtable will be initialized with the
* vcontents of the foodfile in the package (language dependent).
*/
package databaseclasses
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.events.SQLErrorEvent;
	import flash.filesystem.File;

	public class HelpDiabetesSQLConnection
	{
		private  static var sqlConnection:SQLConnection;
		private  static  var dbFile:File = File.applicationStorageDirectory.resolvePath("database/HelpDiabetes.db");

		/**
		 * constructor will open the database asynchronously, as a result the the connection may still be null when the constructor finishes.
		 * In case the database is not yet existing, then it will be created and initialized .. this make take time so the client must take into account that an 
		 * update may happen later 
		 */
		public function HelpDiabetesSQLConnection()
		{
			if (sqlConnection == null)
				sqlConnection = new SQLConnection();
			sqlConnection.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			sqlConnection.openAsync(dbFile,SQLMode.UPDATE);
		}
		
		/**
		 * returns the sqlConnection, may be null
		 */
		public function getHelpDiabetesSQLConnection():SQLConnection {
			return sqlConnection;
		}
		
		private function errorHandler(event:SQLErrorEvent):void {
			switch(event.errorID) {
				case 3125:
			}			
		}
	}
}