	<!--
	Copyright (C) 2011  hippoandfriends
	
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
	
	-->
<!--
based on Survey Ape - Mobile on http://labs.adobe.com/technologies/flexsdk_hero/samples/
-->
package databaseclasses
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class Database extends EventDispatcher
	{
		private var dbFile:File;
		public var aConn:SQLConnection;		
		private var sqlStatementFactory:SQLStatementFactory;
		
		public static const TABLES_CREATED:String = "TABLES_CREATED";
		
		private const MG_DL:String = "mg/dL";
		private const mmol:String="mmol";
		private const dbFileName:String="HelpDiabetes.db"
		
		
		private const CREATE_TABLE_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS fooditems (itemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																							"description TEXT NOT NULL)";
		private const CREATE_TABLE_UNITS:String = "CREATE TABLE IF NOT EXISTS units (unitid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																					"fooditems_itemid INTEGER NOT NULL, " +
																					"description TEXT NOT NULL, " +
																					"standardamount INTEGER, " +
																					"weight INTEGER, " +
																					"kcal INTEGER, " +
																					"protein REAL, " +
																					"carbs REAL NOT NULL, " +
																					"fat REAL);";
		private const CREATE_TABLE_EVENTS:String = "CREATE TABLE IF NOT EXISTS events (eventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																					  "exerciseevents_exerciseeventid INTEGER ," +
																					  "medicinevents_medicineventid INTEGER, " +
																					  "bloodglucoseevents_bloodglucoseeventid INTEGER, " +
																					  "mealevents_mealeventid INTEGER, " +
																					  "creationtimestamp TIMESTAMP, " +
																					  ");";
		private const CREATE_TABLE_EXERCISE_EVENTS:String = "CREATE TABLE IF NOT EXISTS exerciseevents (exerciseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																									   "level TEXT, " +
																									   "comment_2 TEXT);";
		private const CREATE_TABLE_BLOODGLUCOSE_EVENTS:String = "CREATE TABLE IF NOT EXISTS bloodglucoseevents (bloodglucoseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											   "unit TEXT NOT NULL, " +
																											   "value INTEGER NOT NULL);";
		private const CREATE_TABLE_MEDICIN_EVENTS:String = "CREATE TABLE IF NOT EXISTS medicinevents (medicineventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																									 "medicinname TEXT NOT NULL, " +
																									 "amount REAL NOT NULL);";		
		private const CREATE_TABLE_MEAL_EVENTS:String = "CREATE TABLE IF NOT EXISTS mealevents (mealeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																							   "mealtype TEXT NOT NULL, " +
																							   "lastmodifiedtimestamp TIMESTAMP NOT NULL);";		
		private const CREATE_TABLE_SELECTED_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS selectedfooditems (selectedfooditemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											 "mealevents_mealeventid INTEGER NOT NULL, " +
																											 "itemdescription TEXT NOT NULL, " +
																											 "unitdescription TEXT, " +
																											 "standardamount INTEGER, " +
						 	    																			 "weight INTEGER, " +
																					   					     "kcal INTEGER, " +
																											 "protein REAL, " +
																											 "carbs REAL NOT NULL, " +
																											 "fat REAL);";		
		private const CREATE_TABLE_TEMPLATE_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS templatefooditems (templateitemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											 "templates_templateid INTEGER NOT NULL, " +
																											 "itemdescription TEXT NOT NULL, " +
																											 "unitdescription TEXT, " +
																											 "standardamount INTEGER, " +
																											 "weight INTEGER, " +
																											 "kcal INTEGER, " +
																											 "protein REAL, " +
																											 "carbs REAL NOT NULL, " +
																											 "fat REAL);";		
		private const CREATE_TABLE_TEMPLATES:String = "CREATE TABLE IF NOT EXISTS templates (templateid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																							"name TEXT NOT NULL);";		

		
		private const GET_FOODITEM:String = "SELECT * FROM fooditems WHERE itemid = :itemid";
		
		/*************/
		private const GET_SURVEYS:String = "SELECT * FROM surveys ORDER BY id DESC";
		private const GET_QUESTIONS:String = "SELECT * FROM questions";
		private const GET_ANSWERS_FOR_QUESTION_ID:String = "SELECT * FROM answers WHERE id IN (SELECT answers_id FROM questions_answers_rel WHERE questions_id = :id)";
		private const GET_LAST_INSERT_ROWID:String = "SELECT last_insert_rowid()";
		private const GET_NUMBER_OF_COMPLETED_SURVEYS:String = "SELECT COUNT(id) FROM SURVEYS";
		private const GET_NUMBER_OF_UPLOADED_SURVEYS:String = "SELECT COUNT(id) FROM SURVEYS WHERE uploaded=1";		
		private const GET_QUESTIONS_AND_RESPONSES_FOR_SURVEY_ID:String = "SELECT q.question_type,q.question,a.answer FROM questions q, responses r LEFT OUTER JOIN answers a on r.answers_id = a.id WHERE r.questions_id = q.id AND r.survey_id = :id";
		private const GET_RESPONSES_FOR_QUESTION:String = "SELECT a.answer,r.answers_id FROM answers a,responses r WHERE r.answers_id = a.id AND r.questions_id = :id ORDER BY r.answers_id";
		
		private const INSERT_INTO_SURVEYS:String = "INSERT INTO surveys (first, last, email, date, uploaded) VALUES ( :first, :last, :email, :date, :uploaded )";
		private const INSERT_INTO_RESPONSES:String = "INSERT INTO responses (survey_id, questions_id, answers_id) VALUES (:survey_id, :questions_id, :answers_id)";
		private const INSERT_INTO_ANSWERS:String = "INSERT INTO answers (answer) VALUES (:answer)";
		
		private const UPDATE_SURVEY_PHOTO_PATH:String = "UPDATE surveys SET photo_path = :photo_path WHERE id = :id";
		/*************/
		/**
		 * constructor, does nothing
		 */
		public function Database()
		{
			
		}
		
		/**
		 * gets the creation data of the database based on db file creation date
		 */
		public function getCreationDateOfDatabase():Date
		{
			var d:Date;
			if ( this.dbFile && this.dbFile.exists )
			{
				d = dbFile.creationDate;
			}
			return d;
		}
		
		/**
		 * deletes the database
		 */
		public function deleteDatabase():Boolean
		{
			var success:Boolean = false;
			if ( this.dbFile ) 
			{				
				if ( this.aConn && this.aConn.connected )
				{
					this.aConn.close(null);	
				}
				
				var fs:FileStream = new FileStream();
				try 
				{
					fs.open(this.dbFile,FileMode.UPDATE);
					while ( fs.bytesAvailable )	
					{
						fs.writeByte(Math.random() * Math.pow(2,32));						
					}
					trace("writing complete");
					fs.close();
					this.dbFile.deleteFile();
					trace("deletion complete");					
					success = true;
				}
				catch (e:Error)
				{
					trace(e.name + ", " + e.message );
					fs.close();
				}				
			}
			return success;
		}
		
		/**
		 * Create the asynchronous connection to the database, then create the tables
		 * 
		 * @param responder:DatabaseResponder Will dispatch result or error events when the tables are created. Dispatches an event with data TABLES_CREATED 
		 *  when all tables have been successfully created. 
		 **/
		public function init(responder:DatabaseResponder):void
		{
			
			var internalResponder:DatabaseResponder = new DatabaseResponder();
			internalResponder.addEventListener(DatabaseEvent.RESULT_EVENT, onResult);
			internalResponder.addEventListener(DatabaseEvent.ERROR_EVENT, onError);						
			openConnection(internalResponder);	
			
			function onResult(de:DatabaseEvent):void
			{
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onError);
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, onResult);				
				createTables(responder);				
			}
			
			function onError(de:DatabaseEvent):void
			{				
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onError);
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, onResult);
			}
		}
		
		/**
		 * opens the sql connection, if database is not existing yet then it will be created
		 * if creation successful then initializes sqlStatementFactory and dispatches event "RESULT_EVENT"
		 * if not successful then dispatches ERROR_EVENT
		 */
		private function openConnection(responder:DatabaseResponder):void
		{
			this.aConn = new SQLConnection();
			this.aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
			this.aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
			this.aConn.openAsync(dbFile, SQLMode.CREATE);
			
			function onConnOpen(se:SQLEvent):void
			{
				trace("SQL Connection successfully opened. Database:0001");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);					
				sqlStatementFactory = new SQLStatementFactory(aConn);					
				var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
				responder.dispatchEvent(de);				
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				trace("SQL Error while attempting to open database. Database:0002");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);
				
				var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
				responder.dispatchEvent(de);
			}
		}
		
		/**
		 * Will execute SQL that will either create the tables in a fresh database or return, if they're already creatd.
		 **/
		public function createTables(responder:DatabaseResponder):void
		{						
			createFoodItemsTable([responder]);				
		}
		
		/**
		 * Creates the fooditems table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createFoodItemsTable(args:Array):void
		{	
			if ( args[0] is DatabaseResponder )
			{						
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_FOODITEMS, createUnitsTable)
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Creates the units table.
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createUnitsTable(args:Array):void
		{			
			if ( args[0] is DatabaseResponder ) 
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_UNITS, createEventsTable);
				sqlWrapper.statement.execute();				
			}
		}	
		
		/**
		 * Creates the events table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/	
		private function createEventsTable(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_EVENTS, createExerciseEventsTable);
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Creates the create exerciseevents table table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createExerciseEventsTable(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_EXERCISE_EVENTS, createBloodglucoseEventsTable);
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Creates the bloodglucoseevents table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createBloodglucoseEventsTable(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_BLOODGLUCOSE_EVENTS, createMedicinEventsTable);
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Creates the medicinevents table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createMedicinEventsTable(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_MEDICIN_EVENTS, createTableMealEvents);
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Creates the mealevents table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createTableMealEvents(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_MEAL_EVENTS, createTableSelectedFoodItems);
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Creates the selectedfooditems table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createTableSelectedFoodItems(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_SELECTED_FOODITEMS, createTableTemplateFoodItems);
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Creates the templatefooditems table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createTableTemplateFoodItems(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_TEMPLATE_FOODITEMS, createTableTemplates);
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Creates the templates table
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		private function createTableTemplates(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], CREATE_TABLE_FOODITEMS, finishedCreatingTables);
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Dispatches a complete event
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder
		 **/
		private function finishedCreatingTables(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
				de.data = Database.TABLES_CREATED;
				args[0].dispatchEvent(de);
			}
		}
		
		/**
		 * Gets the list of surveys
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder.
		 **/
		public function getSurveys(args:Array):void
		{					
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_SURVEYS);
				sqlWrapper.statement.execute();
			}
		}	
		
		
		/**
		 * Gets a fooditem from the fooditems table. Selects by itemid
		 * 
		 * @param args Array [responder:DatabaseResponder, itemid:Number]
		 **/
		public function getFoodItem(args:Array):void
		{					
			if ( args[0] is DatabaseResponder && args[1] is Number )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_FOODITEM);
				sqlWrapper.statement.parameters[":itemid"] = args[1];
				sqlWrapper.statement.execute();
			}
		}	
		
		/*******************************************************************************
		 * Gets all questions from the database
		 * 
		 * @param args Array [responder:DatabaseResponder]
		 **/
		public function getQuestions(args:Array):void
		{					
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_QUESTIONS);				
				sqlWrapper.statement.execute();
			}
		}	
		
		/**
		 * Inserts into the surveys table. Arguments must be as specified
		 * 
		 * @param args Array [responder:DatabaseResponder, personObject:Object]
		 * personObject consists of key value pairs:
		 * 		first:String, 
		 * 		last:String, 
		 * 		email:String, 
		 * 		date:Date, 
		 * 		uploaded:Boolean;
		 **/
		public function insertIntoSurveys(args:Array):void
		{			
			if ( args[0] is DatabaseResponder && args[1] )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], INSERT_INTO_SURVEYS);
				var person:Object = args[1];
				sqlWrapper.statement.parameters[":first"] = person.first; 
				sqlWrapper.statement.parameters[":last"] =  person.last;
				sqlWrapper.statement.parameters[":email"] = person.email;
				sqlWrapper.statement.parameters[":date"] = person.date;
				sqlWrapper.statement.parameters[":uploaded"] = person.uploaded;
				sqlWrapper.statement.execute();
			}
		}
		
		
		/**
		 * Inserts into the answers table. Arguments must be as specified
		 * 
		 * @param args Array [responder:DatabaseResponder, answer:String]
		 **/
		public function insertIntoAnswers(args:Array):void
		{
			if ( args[0] is DatabaseResponder && args[1] is String )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], INSERT_INTO_ANSWERS);				
				sqlWrapper.statement.parameters[":answer"] = args[1];
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Inserts into the responses table. Arguments must be as specified
		 * 
		 * @param args Array [responder:DatabaseResponder, responseObject:Object]
		 * responseObject consists of key value pairs:
		 * 		surveyID:int,
		 * 		questionsID:int,
		 * 		answersID:int;
		 **/
		public function insertIntoResponses(args:Array):void
		{			
			if ( args[0] is DatabaseResponder && args[1] )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], INSERT_INTO_RESPONSES);
				var response:Object = args[1];
				sqlWrapper.statement.parameters[":survey_id"] = response.surveyID; 
				sqlWrapper.statement.parameters[":questions_id"] =  response.questionsID;
				sqlWrapper.statement.parameters[":answers_id"] = response.answersID;
				sqlWrapper.statement.execute();
			}
		}
		
		
		/**
		 * Gets ids and answers from the answers table, where the id of the answer maps up to the question_id in the questions_answers_rel table.
		 *  Thus if you specify a question_id, every answer that's assigned to that question will be returned in an array. 
		 * 		
		 * @param args Array [responder:DatabaseRespodner, id:Number]
		 **/
		public function getAnswersForQuestionId(args:Array):void
		{
			if ( args[0] is DatabaseResponder && args[1] is Number )	
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_ANSWERS_FOR_QUESTION_ID);
				sqlWrapper.statement.parameters[":id"] = args[1];
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Updates the photo_path for a given survey
		 * 		
		 * @param args Array [responder:DatabaseResponder, surveyID:Number, photoPath:String]
		 **/
		public function updateSurveyPhotoPath(args:Array):void
		{
			if ( args[0] is DatabaseResponder && args[1] is Number && args[2] is String )	
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], UPDATE_SURVEY_PHOTO_PATH);
				sqlWrapper.statement.parameters[":id"] = args[1];
				sqlWrapper.statement.parameters[":photo_path"] = args[2];
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Gets the question and responses for a given survey
		 * 		
		 * @param args Array [responder:DatabaseResponder, id:Number]
		 **/
		public function getQuestionsAndResponsesForSurveyId(args:Array):void
		{
			if ( args[0] is DatabaseResponder && args[1] is Number )	
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_QUESTIONS_AND_RESPONSES_FOR_SURVEY_ID);
				sqlWrapper.statement.parameters[":id"] = args[1];
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Gets the list of responses for a question
		 * 		
		 * @param args Array [responder:DatabaseResponder, id:Number]
		 **/
		public function getResponsesForQuestion(args:Array):void
		{
			if ( args[0] is DatabaseResponder && args[1] is Number )	
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_RESPONSES_FOR_QUESTION);
				sqlWrapper.statement.parameters[":id"] = args[1];
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Gets the last inserted rowid, according to the function last_insert_rowid() in SQLite
		 * 		 
		 * @param args Array [responder:DatabaseRespodner]
		 **/
		public function getLastInsertRowId(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_LAST_INSERT_ROWID);				
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Gets the number of completed surveys from the surveys table 
		 * 		 
		 * @param args Array [responder:DatabaseRespodner]
		 **/
		public function getNumberOfCompletedSurveys(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_NUMBER_OF_COMPLETED_SURVEYS);				
				sqlWrapper.statement.execute();
			}
		}
		
		/**
		 * Gets the number of uploaded surveys from the surveys table 
		 * 		 
		 * @param args Array [responder:DatabaseRespodner]
		 **/
		public function getNumberOfUploadedSurveys(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(args[0], GET_NUMBER_OF_UPLOADED_SURVEYS);				
				sqlWrapper.statement.execute();
			}
		}
	}
	}
}