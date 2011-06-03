/**
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
 
 */
/**
 data used through the application
 * also defining constants here
 */
package model
{
	import databaseclasses.FoodItem;
	import databaseclasses.Settings;
	
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import utilities.ExcelSorting;


	public class ModelLocator
		
		
	{
		[ResourceBundle("general")]

		/**
		 * one and only instance of ModelLocator
		 */
		private static var instance:ModelLocator = new ModelLocator();
		
		/**
		 *  foodTables is an array of an array of strings <br>
		* each row consists of array of strings :<br>
		* - the language field as used by the application, not visible to the user <br>
		* - the language of the table, for display on screens to the user, language itself should be in the user's language based on locale<br>
		* - a description of the table, for display on screens to the user, should be in the user's language based on locale <br>
		* The table is read via some public functions <br>
		* It is initialized in the constructor <br>
		*/
		private var foodTables:Array;
		
		/**
		 *  used in some places to calculate the needed width to hold a certain text - offset is the additional space
		 */
		public static const SIZE_OF_LONGEST_TEXT_OFFSET:Number = 20;

		
		public var maximumSearchStringLength:int = 25;
		
		/**** Add bindable application data here ***/
		/**
		 * list of fooditems used throughout the application<br>
		 * in the first place used in foodcounterview 
		 */
		[Bindable]
		public var foodItemList:ArrayCollection = new ArrayCollection(); 

		/**
		 * unitlist used in popup in addfooditemview 
		 */
		[Bindable]
		public var unitList:ArrayCollection; 
		
		/** 
		 * just a variable used when opening the untilist 
		 */
		[Bindable]
		public var width:int = 300;
		
		/**
		 * the arraycollection used as list in trackingview<br>
		 * It us declared here because it will be used in other classes as well, eg during intialization of the application it will already be created and initialized<br>
		 * The trackingList contains all events : mealevents, bloodglucoseevents, exerciseevents and medicinevents. Sorted by timestamp.<br>
		 */ 
		[Bindable]
		public var trackingList:ArrayCollection = new ArrayCollection();
		
		/**
		 * constructor
		 */
		public function ModelLocator()
		{
			
			if (instance != null) throw new Error('Cannot create a new instance. Must use ModelLocator.getInstance().');

			/**
			 *  foodTables is an array of an array of strings <br>
			 * each row consists of array of strings :<br>
			 * - the language field as used by the application, not visible to the user <br>
			 * - the language of the table, for display on screens to the user, language itself should be in the user's language based on locale<br>
			 * - a description of the table, for display on screens to the user, should be in the user's language based on locale <br>
			 * The table is read via some public functions <br>
			 */
			foodTables = new Array(
				new Array("nl",
					ResourceManager.getInstance().getString("general","dutch"),
					ResourceManager.getInstance().getString("general","DutchTable")),
				new Array("en",
					ResourceManager.getInstance().getString("general","english"),
					ResourceManager.getInstance().getString("general","NorwegianTableInEnglish"))
			);
            
			//create the sort for the trackinglist
			var dataSortField:SortField = new SortField();
			dataSortField.name="timeStamp";
			dataSortField.numeric = true;
			var dataSort:Sort = new Sort();
			dataSort.fields = [dataSortField];
			trackingList.sort = dataSort;
			
			instance = this;
			
		}
		
		/** 
		 * return the one and only instance of ModelLocator
		 */
		public static function getInstance():ModelLocator {
			if (instance == null) instance = new ModelLocator();
			return instance;
		}
		
		/** application constants **/
		
		public function getListOfFoodTableLanguages():Array {
		
			var returnvalue:Array = new Array();
			for (var i:int = 0;i < foodTables.length;i++) {
				returnvalue.push(foodTables[i][0]);
			}
			return returnvalue;
		}
		
		/** 
		 * gets the food table language and description in an array of a string, for a specified language indicator
		 * Returns an empty array if language indicator not found
		 */
		public function getFoodTableLanguageAndDescription(language:String):Array {
			var returnValue:Array = new Array();
			for (var i:int = 0;i < foodTables.length;i++) {
				if (foodTables[i][0].toString().toLowerCase() == language.toLowerCase()) {
					returnValue.push(foodTables[i][1]);
					returnValue.push(foodTables[i][2]);
					i = foodTables.length;
				}
			}
			return returnValue;
		}
	}
}