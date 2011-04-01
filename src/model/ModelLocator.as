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
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	
	import objects.FoodItem;
	import objects.FoodTableList;
	
	import utilities.ExcelSorting;


	public class ModelLocator
		
		
	{
		[ResourceBundle("general")]

		/**
		 * one and only instance of ModelLocator
		 */
		private static var instance:ModelLocator = new ModelLocator();
		
		/* foodTables is an array of an array of strings 
		each row consists of array of strings :
		- the language field as used by the application, not visible to the user 
		- the language of the table, for display on screens to the user, language itself should be in the user's language based on locale
		- a description of the table, for display on screens to the user, should be in the user's language based on locale 
		The table is read via some public functions 
		It is initialized in the constructor */
		private var foodTables:Array;
		
		public var maximumSearchStringLength:int = 25;
		
		/**** Add bindable application data here ***/
		[Bindable]
		public var foodItemList:FoodTableList = new FoodTableList(); 

		/**
		 * constructor
		 */
		public function ModelLocator()
		{
			

			/* foodTables is an array of an array of strings 
			each row consists of array of strings :
			- the language field as used by the application, not visible to the user 
			- the language of the table, for display on screens to the user, language itself should be in the user's language based on locale
			- a description of the table, for display on screens to the user, should be in the user's language based on locale 
			The table is read via some public functions */
			foodTables = new Array(
				new Array("nl",
					ResourceManager.getInstance().getString("general","dutch"),
					ResourceManager.getInstance().getString("general","DutchTable")),
				new Array("en",
					ResourceManager.getInstance().getString("general","english"),
					ResourceManager.getInstance().getString("general","NorwegianTableInEnglish"))
			);

			if (instance != null) throw new Error('Cannot create a new instance. Must use ModelLocator.getInstance().');
			instance = this;
			
			var test:ExcelSorting;
			
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