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
 */
package model
{
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;
	import mx.resources.IResourceManager;


	public class ModelLocator
	{
		/**
		 * one and only instance of ModelLocator
		 */
		private static var instance:ModelLocator = new ModelLocator();
		
		private var resourceManager:IResourceManager;


		/**
		 * constructor
		 */
		public function ModelLocator()
		{
			resourceManager = ResourceManager.getInstance();

			foodTables = new Array(
				new Array("nl",resourceManager.getString("general","dutch"),resourceManager.getString("general","DutchTable")),
				new Array("en",resourceManager.getString("general","english"),resourceManager.getString("general","NorwegianTableinEnglish"))
			);
			

			if (instance != null) throw new Error('Cannot create a new instance. Must use ModelLocator.getInstance().');
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
		
		/* foodTables is an array of an array of strings 
		each row consists of array of strings :
		- the language field as used by the application, not visible to the user 
		- the language of the table, for display on screens to the user, language itself should be in the user's language based on locale
		- a description of the table, for display on screens to the user, should be in the user's language based on locale 
		
		The table is read via some public functions */
		private var foodTables:Array;
		
		/**** Add bindable application data here ***/
		[Bindable]
		public var foodItemList:ArrayCollection = new ArrayCollection(); 
		
		public function getListOfFoodTableLanguages():Array {
		
			var returnvalue:Array = new Array();
			for (var i:int = 0;i < foodTables.length;i++) {
				returnvalue.push(foodTables[i][0]);
			}
			return returnvalue;
		}
	}
}