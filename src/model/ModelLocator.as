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
	import myComponents.DayLineItemRenderer;
	import myComponents.DayLineItemRendererWithTotalAmount;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	import spark.components.List;
	import spark.components.View;
	
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
		
		/**
		 * list of meals, mainly used in addfooditem, and also somewhere else, being reset each time addfooditem is opened
		 */
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
		 * no comment 
		 */
		private var _oldestDayLineStoredInTrackingList:Number;
		/**
		 * no comment 
		 */
		private var _youngestDayLineStoredInTrackingList:Number;
		
		private var _initializeTrackingView:Boolean;

		/**
		 * used in tracking view, if true, then ensureindexvisible will be set to value initializeTrackingViewTo 
		 */
		public function get initializeTrackingView():Boolean
		{
			return _initializeTrackingView;
		}

		/**
		 * @private
		 */
		public function set initializeTrackingView(value:Boolean):void
		{
			_initializeTrackingView = value;
		}

		private var _initializeTrackingViewTo:Number;

		/**
		 * used in tracking view, if _initializeTrackingView, then ensureindexvisible will be set to value initializeTrackingViewTo 
		 */
		public function get initializeTrackingViewTo():Number
		{
			return _initializeTrackingViewTo;
		}

		/**
		 * @private
		 */
		public function set initializeTrackingViewTo(value:Number):void
		{
			_initializeTrackingViewTo = value;
		}

		
		/** 
		 * just a variable used when opening the untilist 
		 */
		[Bindable]
		public var width:int = 300;
		
		/**
		 * the arraycollection used as list in trackingview<br>
		 * It is declared here because it will be used in other classes as well, eg during intialization of the application it will already be created and initialized<br>
		 * The trackingList contains all events : mealevents, bloodglucoseevents, exerciseevents and medicinevents and also DayLine objects are stored here. Sorted by timestamp.<br>
		 * any item in the trackinglist must be of a class extended from TrackingViewElement
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
			
			if (instance != null) throw new Error('Cannot create a new instance. Must use ');

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
			
			// at initialization, there's no dayline existing in the tracking, so initialize to 0
			oldestDayLineStoredInTrackingList = 0;
			// at initialization, there's no dayline existing in the tracking, so initialize to something very big
			youngestDayLineStoredInTrackingList = 5000000000000;;
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
				if (trackingList.getItemAt(i) is MealEvent)
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
		 * When the value is changed (ie change from value different from -1), then an event will be dispatched ModelLocator.SELECTEDMEAL_CHANGED<br>
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
		 * reinitializes and populates ModelLocator.meals, from now, inclusive the meal before now, till 7 days after, a meal wil be created<br>
		 * Then all tracking events are checked, each mealevent in there that falls within the start and end of this list of meals, is added, or, in case it's a standard meal, the meal event is added to the meal 
		 * if updateSelectedMeal is true then it will also set the selected meal (selectedMeal) according to current time, ie the second meal (first meal is always previous meal)<br>
		 * also DayLine items are added<br>
		 * at the end meals.refresh is called and so sorted by timeStamp<br>
		 * <br>
		 * Comment added later on - 20/07/2011: probably never used with updateSelectedMeal = false, I had to change something in AddFoodItemView.mxlm, in the creationComplete method, see comment over there
		 */
		public function refreshMeals(updateSelectedMeal:Boolean = true):void {
			meals = new ArrayCollection();
			
			var todayAsDate:Date = new Date();//that's the actual time, in milliseconds since 1970
			var todayAtMidNight:Number = (new Date(todayAsDate.fullYear,todayAsDate.month,todayAsDate.date)).valueOf();//today at 00:00 - well understood local time,
			//so if we are here GMT +2 , it's the number of milliseconds since 1970 till this morning at 00:00 - 2 Hrs, in other words it's yesterday evening at 22:00
			
			var todayHourMinute:Number = todayAsDate.valueOf() - todayAtMidNight;//number of milliseconds since 00:00 in the morning, 
			
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
				_meals.addItem(new DayLine(todayAtMidNight - 86400000 ));
					
				_meals.addItem(new Meal(supper,null,todayAtMidNight - 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
				
				//now add a dayline for today
				_meals.addItem(new DayLine(todayAtMidNight ));
				
				_meals.addItem(new Meal(breakfast,null,todayAtMidNight  + SMALL_OFFSET));
				_meals.addItem(new Meal(lunch,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL  ) )));
				_meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				_meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
				
			} 
			else  if (todayHourMinute < new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL))) 
			{
				//now add a dayline for today
				_meals.addItem(new DayLine(todayAtMidNight ));
				
				_meals.addItem(new Meal(breakfast,null,todayAtMidNight + SMALL_OFFSET));
				_meals.addItem(new Meal(lunch,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL ))));
				_meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				_meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			} 
			else if (todayHourMinute < new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL))) 
			{
				//now add a dayline for today
				_meals.addItem(new DayLine(todayAtMidNight ));
				
				_meals.addItem(new Meal(lunch,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL ))));
				_meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				_meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			} 
			else 
			{
				//now add a dayline for today
				_meals.addItem(new DayLine(todayAtMidNight ));
				
				_meals.addItem(new Meal(snack,null,todayAtMidNight +  new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				_meals.addItem(new Meal(supper,null,todayAtMidNight + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			}
			
			//so we shall fill up the meals as of now till 7 days after
			for (var i:int = 1;i < 8;i++) {
				_meals.addItem(new DayLine(todayAtMidNight + i * 86400000));
				
				_meals.addItem(new Meal(breakfast,null,todayAtMidNight + i * 86400000 + SMALL_OFFSET));
				_meals.addItem(new Meal(lunch,null,todayAtMidNight + i * 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL ))));
				_meals.addItem(new Meal(snack,null,todayAtMidNight + i * 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL ))));
				_meals.addItem(new Meal(supper,null,todayAtMidNight + i * 86400000 + new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL ))));
			}
			
			//now check for each mealevent, if it needs to replace a meal or if it needs to be added, replace if the name corresponds to one of the mealnames
			var mealEventTimeStamp:Date;
			var mealEventTimeStampAtMidNight:Number;
			var mealTimeStamp:Date;
			var mealTimeStampAtMidNight:Number;
			
			if (trackingList.length > 0) {
				for (var j:int = trackingList.length - 1; j >= 0  ; j--) {
					if (trackingList.getItemAt(j) is MealEvent) {
						mealEventTimeStamp = new Date((trackingList.getItemAt(j) as MealEvent).timeStamp);
						mealEventTimeStampAtMidNight = (new Date(mealEventTimeStamp.fullYear,mealEventTimeStamp.month,mealEventTimeStamp.date)).valueOf();//this is again local time, so if it's here GMT+2, then this is actually time in ms - 2 hours
						
						//check if timestamp is within -1 day or maximum + 7 days
						if ((mealEventTimeStampAtMidNight -  todayAtMidNight < 8 * 86400000 + 1) && (todayAtMidNight - mealEventTimeStampAtMidNight < 86400001)) {
							//check if mealeven timestamp is not smaller than first meal timestamp, because then we would simply stop
							if (mealEventTimeStamp.valueOf() < (_meals.getItemAt(1) as Meal).timeStamp) {
								//don't add the mealevent, and stop going through the tracking list
								j = -1;
							} else {
								//seems like we'll have to add the mealevent
								//now go through all meals, find one with the same timeAtMidNight, then check if it's a breakfast, lunch, snack or supper
								var mealFound:Boolean = false;
								for (var k:int = 0; k < _meals.length ;k++) {
									if (_meals.getItemAt(k) is Meal) {
										mealTimeStamp = new Date((_meals.getItemAt(k) as Meal).timeStamp);			
										mealTimeStampAtMidNight = (new Date(mealTimeStamp.fullYear,mealTimeStamp.month,mealTimeStamp.date)).valueOf();
										if (mealTimeStampAtMidNight == mealEventTimeStampAtMidNight) {
											if ((_meals.getItemAt(k) as Meal).mealName.toUpperCase() == 
												(trackingList.getItemAt(j) as MealEvent).mealName.toUpperCase()) {
												mealFound = true;
												_meals.setItemAt(new Meal(null,(trackingList.getItemAt(j) as MealEvent),Number.NaN),k);
											}
										}
									}
								}
								if (!mealFound) {
									_meals.addItem(new Meal(null,(trackingList.getItemAt(j) as MealEvent),Number.NaN));
								}
							}
						}
					}
				}
			}
			
			
			meals.refresh();
			
			if (updateSelectedMeal) {
				resetSelectedMeal();
			}
		}
		
		/**
		 * gets in the meals, the second meal that is one of the standards meals, and assigns it to _selectedMeal
		 */
		public function resetSelectedMeal():void {
			//initiailize selectedMeal to the second meal that is one of the standards meal
			selectedMeal = getRefreshedSelectedMeal();
		}
		
		public function getCurrentlySelectedMeal():Meal {
			return _meals.getItemAt(selectedMeal) as Meal;
		}
		
		/**
		 * this function gets the id of the second meal in the _meals, that is a standard meal
		 */
		public function getRefreshedSelectedMeal():int {
			var breakfast:String = ResourceManager.getInstance().getString('general','breakfast');
			var lunch:String = ResourceManager.getInstance().getString('general','lunch');
			var snack:String = ResourceManager.getInstance().getString('general','snack');
			var supper:String = ResourceManager.getInstance().getString('general','supper');

			var mealCounter:int = 0;
			
			for (var m:int = 0;m < _meals.length;m++) {
				var temp:Object = _meals.getItemAt(m) ;
				var temp2:Object = _meals;
				if ((_meals.getItemAt(m) is Meal) || (_meals.getItemAt(m) is MealEvent)) {
					if (((_meals.getItemAt(m) as Meal).mealName == breakfast) ||
						((_meals.getItemAt(m) as Meal).mealName == lunch) || 
						((_meals.getItemAt(m) as Meal).mealName == snack) ||
						((_meals.getItemAt(m) as Meal).mealName == supper))
						mealCounter++;
					if (mealCounter == 2) {
						return  m;
					}
				}
			}			
			
			//code should never get here
			return 0;
		}
		
		/**
		 * updates insulinratio for all mealevents in trackinglist, with timeStamp > asOfDateAndTime and time of day  between fromTime and toTime<br>
		 * Also database will be updated.<br>
		 */
		public function updateInsulinRatiosInTrackingList(asOfDateAndTime:Number,newInsulinRatio:Number,fromTime:Number,toTime:Number):void {
		   for (var i:int = 0; i <  trackingList.length	;i++)  {
			   if (trackingList.getItemAt(i) is MealEvent) {
				   var mealEvent:MealEvent = trackingList.getItemAt(i) as MealEvent;
				   if (mealEvent.timeStamp >= asOfDateAndTime)	{
					   var mealEventTimeStampAsDate:Date = new Date(mealEvent.timeStamp);
					   //the timestamp but only the hours, minutes and seconds
					   var mealEventTimeStampHourMinute:Number = (new Date(0,0,0,mealEventTimeStampAsDate.hoursUTC,mealEventTimeStampAsDate.minutesUTC,mealEventTimeStampAsDate.secondsUTC)).valueOf();
						if (mealEventTimeStampHourMinute >= fromTime)
							if (mealEventTimeStampHourMinute <= toTime)
								mealEvent.insulinRatio = newInsulinRatio;
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

		/**
		 * the oldest dayline in the tracking list represented as Number, this is the UTC time  in ms, since 1970...
		 */
		public function get oldestDayLineStoredInTrackingList():Number
		{
			return _oldestDayLineStoredInTrackingList;
		}

		/**
		 * @private
		 */
		public function set oldestDayLineStoredInTrackingList(value:Number):void
		{
			_oldestDayLineStoredInTrackingList = value;
		}

		/**
		 * the youngest dayline in the tracking list represented as Number, this is the UTC time  in ms, since 1970...
		 */
		public function get youngestDayLineStoredInTrackingList():Number
		{
			return _youngestDayLineStoredInTrackingList;
		}

		/**
		 * @private
		 */
		public function set youngestDayLineStoredInTrackingList(value:Number):void
		{
			_youngestDayLineStoredInTrackingList = value;
		}
		
	}
}