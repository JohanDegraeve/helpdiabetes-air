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
	import databaseclasses.Meal;
	import databaseclasses.MealEvent;
	import databaseclasses.Settings;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	
	import myComponents.DayLine;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import utilities.ExcelSorting;


	/**
	 * has some data fields used throughout the application<br>
	 * - 
	 */
	public class ModelLocator extends EventDispatcher
		
		
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
		
		private var _meals:ArrayCollection ;

		/**
		 * index to the currently selected meal in meals<br>
		 * initialized to -1 which means invalid value
		 */
		private var _selectedMeal:int = -1;
		/**
		 * used for event dispatching, when selectedMeal changes, except when chaning from value -1<br>
		 */
		public static const SELECTEDMEAL_CHANGED:String="selected_meal_changed";
		/**
		 * used for event dispatching, when selectedMeal initialized, meaning changed form value -1 to value > 0<br>
		 */
		public static const SELECTEDMEAL_INITIALIZED:String="selected_meal_initialized";
		
		/** 
		 * just a variable used when opening the untilist 
		 */
		[Bindable]
		public var width:int = 300;
		
		/**
		 * the arraycollection used as list in trackingview<br>
		 * It us declared here because it will be used in other classes as well, eg during intialization of the application it will already be created and initialized<br>
		 * The trackingList contai ns all events : mealevents, bloodglucoseevents, exerciseevents and medicinevents. Sorted by timestamp.<br>
		 */ 
		[Bindable]
		public var trackingList:ArrayCollection = new ArrayCollection();
		
		/**
		 * a very small offset that will be used when creating meals, to distinguish them from dayline objects
		 */
		private static const SMALL_OFFSET:Number = 1;
		
		/**
		 * dateSortField and dataSort are used for sorting an arraycollection by timeStamp
		 */
		private var dataSortField:SortField = new SortField();
		/**
		 * dateSortField and dataSort are used for sorting an arraycollection by timeStamp
		 */
		private var dataSort:Sort = new Sort();

		
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
            
			//create the sort for the trackinglist and the meals
			dataSortField.name="timeStamp";
			dataSortField.numeric = true;
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
		
		/**
		 * reads from the trackingList the mealevent with identified mealeventid<br>
		 * returns null if not found
		 */
		public function getMealEventFromTrackingList(mealEventId:Number):MealEvent {
			for (var i:int = trackingList.length - 1;i >= 0; i--) {
				if (((trackingList.getItemAt(i)) as MealEvent).mealEventId == mealEventId)
					return (trackingList.getItemAt(i) as MealEvent);
			}
			return null;
		}

		/**
		 * index to the currently selected meal in meals<br>
		 * initialized to -1 which means invalid value, it's the database initialization that will set it to a valid value
		 */
		public function get selectedMeal():int
		{
			return _selectedMeal;
		}

		/**
		 * index to the currently selected meal in meals<br>
		 * initialized to -1 which means invalid value, it's the database initialization that will set it to a valid value<br>
		 * When the value is initialized by database.init (ie change from value -1), then an event will be dispatched ModelLocator.SELECTEDMEAL_INITIALIZED<br>
		 * When the value is changed (ie change from value different from -1), then an event will be dispatched ModelLocator.SELECTEDMEAL_CHANGED
		 */
		public function set selectedMeal(value:int):void
		{
			if (_selectedMeal == -1) {
				_selectedMeal = value;
				this.dispatchEvent(new Event(ModelLocator.SELECTEDMEAL_INITIALIZED));
			} else {
				_selectedMeal = value;
				this.dispatchEvent(new Event(ModelLocator.SELECTEDMEAL_CHANGED));
			}
		}
		
		/**
		 * reinitializes and populates ModelLocator.meals <br>
		 * if updateSelectedMeal is true then it will also set the selected meal (selectedMeal) according to current time, ie the second meal (first meal is always previous meal)<br>
		 * als DayLine items are added<br>
		 * at the end meals.refresh is called and so sorted by timeStamp
		 */
		public function refreshMeals(updateSelectedMeal:Boolean = true):void {
			_meals = new ArrayCollection();
			
			var todayAsDate:Date = new Date();//that's the actual time
			var todayAtMidNight:Number = (new Date(todayAsDate.fullYear,todayAsDate.month,todayAsDate.date)).valueOf();//today at 00:00
			var todayHourMinute:Number = todayAsDate.valueOf() - todayAtMidNight;
			
			//to avoid having to get the resource each time, we'll do it once here
			var breakfast:String = ResourceManager.getInstance().getString('general','breakfast');
			var lunch:String = ResourceManager.getInstance().getString('general','lunch');
			var snack:String = ResourceManager.getInstance().getString('general','snack');
			var supper:String = ResourceManager.getInstance().getString('general','supper');
			
			//the first meal to add, is the  meal just before the current period
			//then we'll fill up with all meals from today till 7 days after
			//then we go through the mealevents, and where applicable replace the meal with a new meal that has the mealevent
			
			
			if (todayHourMinute < new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL))) {
				//first add add a dayline for yesterday
				ModelLocator.getInstance()._meals.addItem(new DayLine(todayAtMidNight - 86400000 ));
					
				ModelLocator.getInstance()._meals.addItem(new Meal(supper,null,todayAtMidNight - 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
				
				//now add a dayline for today
				ModelLocator.getInstance()._meals.addItem(new DayLine(todayAtMidNight ));
				
				ModelLocator.getInstance()._meals.addItem(new Meal(breakfast,null,todayAtMidNight  + SMALL_OFFSET));
				ModelLocator.getInstance()._meals.addItem(new Meal(lunch,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL  ) )));
				ModelLocator.getInstance()._meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
				
			} 
			else  if (todayHourMinute < new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL))) 
			{
				//now add a dayline for today
				ModelLocator.getInstance()._meals.addItem(new DayLine(todayAtMidNight ));
				
				ModelLocator.getInstance()._meals.addItem(new Meal(breakfast,null,todayAtMidNight + SMALL_OFFSET));
				ModelLocator.getInstance()._meals.addItem(new Meal(lunch,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			} 
			else if (todayHourMinute < new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL))) 
			{
				//now add a dayline for today
				ModelLocator.getInstance()._meals.addItem(new DayLine(todayAtMidNight ));
				
				ModelLocator.getInstance()._meals.addItem(new Meal(lunch,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			} 
			else 
			{
				//now add a dayline for today
				ModelLocator.getInstance()._meals.addItem(new DayLine(todayAtMidNight ));
				
				ModelLocator.getInstance()._meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			}
			
			//so we shall fill up the meals as of now till 7 days after
			for (var i:int = 1;i < 8;i++) {
				ModelLocator.getInstance()._meals.addItem(new DayLine(todayAtMidNight + i * 86400000));
				
				ModelLocator.getInstance()._meals.addItem(new Meal(breakfast,null,todayAtMidNight + i * 86400000 + SMALL_OFFSET));
				ModelLocator.getInstance()._meals.addItem(new Meal(lunch,null,todayAtMidNight + i * 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(snack,null,todayAtMidNight + i * 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				ModelLocator.getInstance()._meals.addItem(new Meal(supper,null,todayAtMidNight + i * 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			}
			
			//now check for each mealevent, if it needs to replace a meal or if it needs to be added, replace if the name corresponds to one of the mealnames
			var mealEventTimeStamp:Date;
			var mealEventTimeStampAtMidNight:Number;
			var mealTimeStamp:Date;
			var mealTimeStampAtMidNight:Number;
			
			if (ModelLocator.getInstance().trackingList.length > 0) {
				for (var j:int = ModelLocator.getInstance().trackingList.length - 1; i >= 0  ; i--) {
					mealEventTimeStamp = new Date((ModelLocator.getInstance().trackingList.getItemAt(j) as MealEvent).timeStamp);
					mealEventTimeStampAtMidNight = (new Date(mealEventTimeStamp.fullYear,mealEventTimeStamp.month,mealEventTimeStamp.date)).valueOf();
					
					//check if timestamp is within -1 day or maximum + 7 days
					if ((mealEventTimeStampAtMidNight -  todayAtMidNight < 8 * 86400000 + 1) && (todayAtMidNight - mealEventTimeStampAtMidNight < 86400001)) {
						//seems like we'll have to add the mealevent
						//now go through all meals, find one with the same timeAtMidNight, then check if it's a breakfast, lunch, snack or supper
						var mealFound:Boolean = false;
						for (var k:int = 0; k < ModelLocator.getInstance()._meals.length ;k++) {
							if (ModelLocator.getInstance()._meals.getItemAt(k) is Meal) {
								mealTimeStamp = new Date((ModelLocator.getInstance()._meals.getItemAt(k) as Meal).timeStamp);			
								mealTimeStampAtMidNight = (new Date(mealTimeStamp.fullYear,mealTimeStamp.month,mealTimeStamp.date)).valueOf();
								if (mealTimeStampAtMidNight == mealEventTimeStampAtMidNight) {
									if ((ModelLocator.getInstance()._meals.getItemAt(k) as Meal).mealName.toUpperCase() == 
										(ModelLocator.getInstance().trackingList.getItemAt(j) as MealEvent).mealName.toUpperCase()) {
										mealFound = true;
										ModelLocator.getInstance()._meals.setItemAt(new Meal(null,(ModelLocator.getInstance().trackingList.getItemAt(j) as MealEvent),Number.NaN),k);
									}
								}
							}
						}
						if (!mealFound) {
							ModelLocator.getInstance()._meals.addItem(new Meal(null,(ModelLocator.getInstance().trackingList.getItemAt(j) as MealEvent),Number.NaN));
						}
					}
				}
			}
			
			
			meals.refresh();
			
			if (updateSelectedMeal) {
				//initiailize ModelLocator.getInstance().selectedMeal to the second meal that is one of the standards meal
				var mealCounter:int = 0;
				
				for (var m:int = 0;m < ModelLocator.getInstance()._meals.length;m++) {
					if (ModelLocator.getInstance()._meals.getItemAt(m) is Meal) {
						if (((ModelLocator.getInstance()._meals.getItemAt(m) as Meal).mealName == breakfast) ||
							((ModelLocator.getInstance()._meals.getItemAt(m) as Meal).mealName == lunch) || 
							((ModelLocator.getInstance()._meals.getItemAt(m) as Meal).mealName == snack) ||
							((ModelLocator.getInstance()._meals.getItemAt(m) as Meal).mealName == supper))
							mealCounter++;
						if (mealCounter == 2) {
							selectedMeal = m;
						}
					}
				}			
			}

		}

		[Bindable]
		/**
		 * list of meals, initialized by database initiation<br>
		 * to be used when selecting a meal in addfooditemview.
		 */
		public function get meals():ArrayCollection
		{
			return _meals;
		}

		/**
		 * @private
		 */
		public function set meals(value:ArrayCollection):void
		{
			_meals = value;
			//create the sort for the trackinglist and the meals
			_meals.sort = dataSort;

		}

	}
}