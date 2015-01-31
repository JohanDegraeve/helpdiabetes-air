/**
 Copyright (C) 2013  hippoandfriends
 
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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import databaseclasses.Meal;
	import databaseclasses.MealEvent;
	import databaseclasses.MedicinEvent;
	import databaseclasses.Settings;
	
	import myComponents.DayLine;
	import myComponents.SimpleTextEvent;
	import myComponents.TrackingViewElement;
	
	import utilities.FromtimeAndValueArrayCollection;
	
	/**
	 * has some data fields used throughout the application<br>
	 * - 
	 */
	public class ModelLocator extends EventDispatcher
		
		
	{
		[ResourceBundle("general")]
		[ResourceBundle("helpdiabetes")]
		
		/**
		 * one and only instance of ModelLocator
		 */
		private static var instance:ModelLocator = new ModelLocator();
		
		/**
		 *  foodTables is an array of an array of strings <br>
		 * each row consists of array of strings :<br>
		 * - the language field as used by the application, not visible to the user <br>
		 * - the language of the table, for display on screens to the user, language itself should be in the user's language based on settings<br>
		 * - a description of the table, for display on screens to the user, should be in the user's language based on locale <br>
		 * The table is read via some public functions <br>
		 * It is initialized in the constructor <br>
		 */
		private var foodTables:Array;
		
		public var maximumSearchStringLength:int = 25;
		
		/**
		 * if searchActive, then this is eventid of the lastmarked item , 0 means there's no item marked
		 */
		public var lastMarkedItemEventId:Number;
		/**
		 * if searchActive, then this is eventid of the firstmarked item, 0 means there's no item marked 
		 */
		public var firstMarkedItemEventId:Number;
		
		private  var _searchActive:Boolean = false;
		/**
		 * used for event dispatching, when searchactive changes
		 */public static const SEARCHACTIVE_CHANGED:String="searchactive_changed";
		
		[Bindable]
		/**
		 * used in tracking view, true means a search has been made, some elements in the tracking list are marked 
		 */
		public function get searchActive():Boolean
		{
			return _searchActive;
		}
		
		private static var counter:int = 0;
		
		/**
		 * sets searchActive<br>
		 * set firstmarkeditemeventid and lastmarkeditemeventid to 0, and sets the mark for all trackingevents to false
		 */
		public function set searchActive(value:Boolean):void
		{
			if (_searchActive == value)
				return;
			_searchActive = value;
			if (!_searchActive) {
				firstMarkedItemEventId = 0;
				lastMarkedItemEventId = 0;
				for (var trackingcntr:int = 0;trackingcntr < trackingList.length;trackingcntr++) {
					(trackingList.getItemAt(trackingcntr) as TrackingViewElement).mark = false;
				}
			}
			this.dispatchEvent(new Event(ModelLocator.SEARCHACTIVE_CHANGED));
		}
		
		
		/**** Add bindable application data here ***/
		private var _foodItemList:ArrayCollection = new ArrayCollection(); 
		
		[Bindable]
		/**
		 * list of fooditems used throughout the application<br>
		 * in the first place used in foodcounterview 
		 */
		public function get foodItemList():ArrayCollection
			
		{
			return _foodItemList;
		}
		
		/**
		 * @private
		 */
		
		public function set foodItemList(value:ArrayCollection):void
			
		{
			_foodItemList = value;
		}
		
		
		/**
		 * list of meals, mainly used in addfooditem, and also somewhere else, being reset each time addfooditem is opened
		 */
		private var _meals:ArrayCollection;
		
		/**
		 * index to the currently selected meal in meals<br>
		 * initialized to -1 which means invalid value
		 */
		private var _selectedMeal:int = -1;
		
		private var _trackingEventToShow:Number = -1;
		
		/**
		 * eventid of to the tracking event to show when going to trackingview<br>
		 * initially set to -1, in the get trackingeventToShow, when still on -1 it will be set to the event id of the last event in the _trackingList, except when 
		 * there are no elements in the _trackingList, then it stays -1
		 */
		public function get trackingEventToShow():Number
			
		{
			if (_trackingEventToShow == -1)
				if (_trackingList.length > 0)
					_trackingEventToShow = (_trackingList.getItemAt(_trackingList.length -1) as TrackingViewElement).eventid;
			return _trackingEventToShow;
		}
		
		/**
		 * @private
		 */
		
		public function set trackingEventToShow(value:Number):void
			
		{
			_trackingEventToShow = value;
		}
		
		
		/**
		 * used for event dispatching, when selectedMeal changes, except when chaning from value -1<br>
		 */
		public static const SELECTEDMEAL_CHANGED:String="selected_meal_changed";
		/**
		 * used for event dispatching, when selectedMeal initialized, meaning changed from value -1 to value > 0<br>
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
		
		/** 
		 * just a variable used when opening the untilist 
		 */
		[Bindable]
		public var width:int = 300;
		
		private var _trackingList:ArrayCollection;
		
		
		[Bindable]
		
		/**
		 * copyOfTrackingList is the arraycollection used as list in the trackingview<br>
		 * trackingList is the list that will be maintained, copy is simply set equal to trackinglist, but when doing lots of changes
		 * then copy can be set to null temporarily, do the changes on trackinglist, and then reassign copy to trackinglist<br><br>
		 * the arraycollection used as list in trackingview<br>
		 * It is declared here because it will be used in other classes as well, eg during intialization of the application it will already be created and initialized<br>
		 * The _trackingList contains all events : mealevents, bloodglucoseevents, exerciseevents and medicinevents and also DayLine objects are stored here. Sorted by timestamp.<br>
		 * any item in the _trackingList must be of a class extended from TrackingViewElement
		 */
		public function get trackingList():ArrayCollection
			
		{
			return _trackingList;
		}
		
		/**
		 * @private
		 */
		
		public function set trackingList(value:ArrayCollection):void
			
		{
			_trackingList = value;
			//create the sort for the _trackingList and the meals
			dataSortField.name="timeStamp";
			dataSortField.numeric = true;
			dataSort.fields = [dataSortField];
			_trackingList.sort = dataSort;
		}
		
		private var _copyOfTrackingList:ArrayCollection;
		
		[Bindable]
		/**
		 * copyOfTrackingList is the arraycollection used as list in the trackingview<br>
		 * trackingList is the list that will be maintained, copy is simply set equal to trackinglist, but when doing lots of changes
		 * then copy can be set to another array (..) temporarily, do the changes on trackinglist, and then reassign copy to trackinglist<br><br>
		 * the arraycollection used as list in trackingview<br>
		 * This temporary "another array" can show that sync is busy<br>
		 * It is declared here because it will be used in other classes as well, eg during intialization of the application it will already be created and initialized<br>
		 * The _trackingList contains all events : mealevents, bloodglucoseevents, exerciseevents and medicinevents and also DayLine objects are stored here. Sorted by timestamp.<br>
		 * any item in the _trackingList must be of a class extended from TrackingViewElement
		 */
		public function get copyOfTrackingList():ArrayCollection
			
		{
			return _copyOfTrackingList;
		}
		
		public function set copyOfTrackingList(value:ArrayCollection):void
			
		{
			_copyOfTrackingList = value;
		}
		
		/**
		 * an array collection that has a message saying that sync is busy<br>
		 * copyoftrackinglist can be assigned to this list temporarily. 
		 */
		public var infoTrackingList:ArrayCollection;
		
		
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
		 * the calculated height that a styleabletextfield would normally have, calculated somewhere during startup 
		 static public var StyleableTextFieldCalculatedHeight:Number = 0;
		 
		/**
		 * the  preferred height that a styleabletextfield would normally have, calculated somewhere during startup 
		 static public var StyleableTextFieldPreferredHeight:Number = 0;
		 
		 static private var _offSetSoThatTextIsInTheMiddle:Number=0;*/
		
		/**
		 * application just started ?
		 */
		public var firstInitOfFoodCounterView:Boolean = true;
		
		public static var debugMode:Boolean = false;

		public static var BOLUS_AMOUNT_FOR_SQUARE_WAVE_BOLUSSES:Number = 0.1;//unit s of insulin

		public  function extendedFunctionsActive():Boolean
		{
			return true;
			//return Settings.getInstance().getSetting(Settings.SettingsExtendedFunctionsActive) == "true" ? true:false;
		}

		
		/**
		 * offset to be used top and bottom of a label itemrenderer, to make sure the text is in the middle
		 public static function get offSetSoThatTextIsInTheMiddle():Number
		 
		 {
		 if (_offSetSoThatTextIsInTheMiddle == 0)
		 _offSetSoThatTextIsInTheMiddle = (StyleableTextFieldCalculatedHeight - StyleableTextFieldPreferredHeight)/2;
		 return _offSetSoThatTextIsInTheMiddle;
		 }*/
		
		/**
		 * constructor
		 */
		public function ModelLocator()
		{
			//
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
					ResourceManager.getInstance().getString("general","NorwegianTableInEnglish")),
				new Array("fr",
					ResourceManager.getInstance().getString("general","french"),
					ResourceManager.getInstance().getString("general","FrenchAxelle")),
				new Array("ro",
					ResourceManager.getInstance().getString("general","romanian"),
					ResourceManager.getInstance().getString("general","RomanianOnedenDotCom"))
			);
			
			trackingList = new ArrayCollection();
			copyOfTrackingList = trackingList;
			
			instance = this;
			
			// at initialization, there's no dayline existing in the tracking, so initialize to 0
			_oldestDayLineStoredInTrackingList = 0;
			// at initialization, there's no dayline existing in the tracking, so initialize to something very big
			_youngestDayLineStoredInTrackingList = 5000000000000;
			
			infoTrackingList = new ArrayCollection();
			infoTrackingList.addItem(new SimpleTextEvent(ResourceManager.getInstance().getString("general","storingnewevents")));
			
		}
		
		/** 
		 * return the one and only instance of ModelLocator
		 */
		public static function getInstance():ModelLocator {
			if (instance == null) instance = new ModelLocator();
			return instance;
		}
		
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
		 * reads from the _trackingList the mealevent with identified mealeventid<br>
		 * returns null if not found
		 */
		public function getMealEventFromTrackingList(mealEventId:Number):MealEvent {
			for (var i:int = _trackingList.length - 1;i >= 0; i--) {
				if (_trackingList.getItemAt(i) is MealEvent)
					if (((_trackingList.getItemAt(i)) as MealEvent).eventid == mealEventId)
						return (_trackingList.getItemAt(i) as MealEvent);
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
		 * When selectedMeal is changed, then also tarckingEventToShow gets the new value
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
			if ((meals.getItemAt(_selectedMeal) as Meal).mealEvent)
				trackingEventToShow = ((meals.getItemAt(_selectedMeal) as Meal).mealEvent).eventid;
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
			
			/**
			 * that's the actual time, in milliseconds since 1970, utc
			 */
			var todayAsDate:Date = new Date();
			/**
			 * today at 00:00 local but in utc milliseconds,<br>
			 * so if we are here GMT +2 , it's the number of milliseconds since 1970 till this morning at 00:00 - 2 Hrs, in other words it's yesterday evening at 22:00<br>
			 */
			var todayAtMidNight:Number = (new Date(todayAsDate.fullYear,todayAsDate.month,todayAsDate.date)).valueOf();
			
			/**
			 * number of milliseconds since 00:00 in the morning<br>
			 * but local, so for example if it's here in Belgium 10:03, then this value = (10*3600 + 3*60)*1000, no matter what the utc time is.
			 */
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
			/**
			 * mealEventTimeStamp as Date
			 */
			var mealEventTimeStamp:Date;
			/**
			 * timestamp in ms utc, starting 1st of january 1970
			 */
			var mealEventTimeStampAtMidNight:Number;
			/**
			 * mealTimeStamp as Date
			 */
			var mealTimeStamp:Date;
			/**
			 * timestamp in ms, utc, starting 1st of january 1970
			 */
			var mealTimeStampAtMidNight:Number;
			
			if (_trackingList.length > 0) {
				for (var j:int = _trackingList.length - 1; j >= 0  ; j--) {
					if (_trackingList.getItemAt(j) is MealEvent) {
						mealEventTimeStamp = new Date((_trackingList.getItemAt(j) as MealEvent).timeStamp);
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
											if ((_meals.getItemAt(k) as Meal).mealEvent == null) {//see fix in r347
												if ((_meals.getItemAt(k) as Meal).mealName.toUpperCase() == 
													(_trackingList.getItemAt(j) as MealEvent).mealName.toUpperCase()) {
													mealFound = true;
													_meals.setItemAt(new Meal(null,(_trackingList.getItemAt(j) as MealEvent),Number.NaN),k);
													k = _meals.length;
												}
											}
										}
									}
								}
								if (!mealFound) {
									_meals.addItem(new Meal(null,(_trackingList.getItemAt(j) as MealEvent),Number.NaN));
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
		 * sets selectedMeal to the second meal that is one of the standards meals<br>
		 * returns the new value
		 */
		public function resetSelectedMeal():int {
			//initiailize selectedMeal to the second meal that is one of the standards meal
			selectedMeal = getRefreshedSelectedMeal();
			return selectedMeal;
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
		 * updates insulinratio for all mealevents in _trackingList, with timeStamp >= asOfDateAndTime and time of day  between fromTime and toTime whereby ,
		 * asOfDateAndTime is ms since 1st of January 1970 UTC<br>
		 * <br>fromTime and toTime are local time, as example :<br>
		 * if it's here in Belgium 10:03, then this value = (10*3600 + 3*60)*1000, no matter what the utc time is.<br>
		 * Also database will be updated.<br>
		 */
		public function updateInsulinRatiosInTrackingList(asOfDateAndTime:Number,newInsulinRatio:Number,fromTime:Number,toTime:Number):void {
			for (var i:int = 0; i <  _trackingList.length	;i++)  {
				if (_trackingList.getItemAt(i) is MealEvent) {
					var mealEvent:MealEvent = _trackingList.getItemAt(i) as MealEvent;
					if (mealEvent.timeStamp >= asOfDateAndTime)	{
						var mealEventTimeStampAsDate:Date = new Date(mealEvent.timeStamp);
						//the timestamp but only the hours, minutes and seconds
						var mealEventTimeStampHourMinute:Number =  (mealEventTimeStampAsDate.hours * 3600 + mealEventTimeStampAsDate.minutes * 60 + mealEventTimeStampAsDate.seconds)*1000;;//(new Date(1970,0,1,mealEventTimeStampAsDate.hoursUTC,mealEventTimeStampAsDate.minutesUTC,mealEventTimeStampAsDate.secondsUTC,0)).valueOf();
						if (mealEventTimeStampHourMinute >= fromTime)
							if (mealEventTimeStampHourMinute < toTime)
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
		
		private function set meals(value:ArrayCollection):void
			
		{
			
			_meals = value;
			//create the sort for the _trackingList and the meals
			_meals.sort = dataSort;
		}
		
		/**
		 * adds a meal and returns the index of the newly stored meal, after refreshing 
		 */
		public function addMeal(newMeal:Meal):int {
			_meals.addItem(newMeal);
			_meals.refresh();
			return _meals.getItemIndex(newMeal);
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
		
		/**
		 * recalculates the insulinamounts in all mealevents in the trackinglist, with a timestamp younger then specified asof<br>
		 * asof represents time in ms since 1970 blabla
		 */
		public function recalculateInsulinAmoutInAllYoungerMealEvents(asOf:Number):void {
			for (var cntr:int = trackingList.length - 1;cntr >= 0;cntr--) {
				if (trackingList.getItemAt(cntr) is MealEvent) {
					if ((trackingList.getItemAt(cntr) as MealEvent).timeStamp > asOf) {
						(trackingList.getItemAt(cntr) as MealEvent).recalculateInsulinAmount();
					} else {
						break;
					}
				}
			}
		}
		/**
		 * updates correctionfactors in all existing mealevents, according to correction factor stored in the setting<br>
		 */
		public function resetCorrectionFactorsInMeals(asOf:Date):void {
			var  CFList:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(Settings.getInstance().getSetting(Settings.SettingsCorrectionFactor));
			for (var cntr:int = trackingList.length - 1;cntr >= 0;cntr--) {
				if (trackingList.getItemAt(cntr) is MealEvent) {
					if ((trackingList.getItemAt(cntr) as MealEvent).timeStamp > asOf.time) {
						(trackingList.getItemAt(cntr) as MealEvent).correctionFactor = CFList.getValue(Number.NaN,"",new Date((trackingList.getItemAt(cntr) as MealEvent).timeStamp));
					} else {
						break;
					}
				}
			}
		}
		
		/**
		 * calculates active insulin at given time, if time = null then active insulin now is calculated, time in ms since 1 1 1970
		 */
		public function calculateActiveInsulin(time:Number = NaN):Number  {
			
			var maxInsulinDurationInSeconds:Number = new Number(Settings.getInstance().getSetting(Settings.SettingsMaximumInsulinDurationInSeconds));
			
			//trace("in calculateActiveInsulin " + ++counter);
			if (isNaN(time))
				time = (new Date()).valueOf();

			var activeInsulin:Number = new Number(0);
			for (var cntr:int = copyOfTrackingList.length - 1; cntr >= 0 ; cntr-- ) {
				//trace("cntr = " + cntr + " date = " + (new Date((copyOfTrackingList.getItemAt(cntr) as TrackingViewElement).timeStamp)).toString());
				//we go back maximum maxInsulinActivity
				if ((copyOfTrackingList.getItemAt(cntr) as TrackingViewElement).timeStamp + maxInsulinDurationInSeconds * 1000 < time)
					break;
				if ((copyOfTrackingList.getItemAt(cntr) as TrackingViewElement).timeStamp < time) {//we don't include events in the future
					if (copyOfTrackingList.getItemAt(cntr) is MedicinEvent) {
						var theEvent:MedicinEvent = copyOfTrackingList.getItemAt(cntr) as MedicinEvent;
						activeInsulin += calculateActiveInsulinForSpecifiedEvent(theEvent, time);						
					}
				}
			}
			return activeInsulin;
		}
		
		/**
		 * For a specific medicin event, calculates active insulin at the specified time, time in milliseconds<br>
		 */
		public function calculateActiveInsulinForSpecifiedEvent(theEvent:MedicinEvent, time:Number = NaN):Number {
			var maxInsulinDurationInSeconds:Number = new Number(Settings.getInstance().getSetting(Settings.SettingsMaximumInsulinDurationInSeconds));
			if ((theEvent as TrackingViewElement).timeStamp + maxInsulinDurationInSeconds * 1000 < time)
				return new Number(0);
			//let's find if the name of the medicinevent matches one of the medicins in the settings
			var activeInsulin:Number = new Number(0);
			for (var medicincntr:int = 0;medicincntr <  5;medicincntr++) {
				if (Settings.getInstance().getSetting( Settings.SettingsInsulinType1 + medicincntr) == theEvent.medicinName)  {
					if (Settings.getInstance().getSetting(Settings.SettingsMedicin1_AOBActive + medicincntr) == "true")  {
						//..zien welke range we moeten nemen
						var x_valueasString:String = (Settings.getInstance().getSetting(Settings.SettingsMedicin1_range1_AOBChart + medicincntr * 4).split("-")[0] as String).split(":")[1];
						var y_valueasString:String = (Settings.getInstance().getSetting(Settings.SettingsMedicin1_range2_AOBChart + medicincntr * 4).split("-")[0] as String).split(":")[1];
						var z_valueasString:String = (Settings.getInstance().getSetting(Settings.SettingsMedicin1_range3_AOBChart + medicincntr * 4).split("-")[0] as String).split(":")[1];
						var x_value:Number = Number(x_valueasString);
						var y_value:Number = Number(y_valueasString);
						var z_value:Number = Number(z_valueasString);
						var settingToUse:int;	
						if (theEvent.amount < x_value)
							settingToUse = Settings.SettingsMedicin1_range1_AOBChart + medicincntr * 4;
						else if (theEvent.amount < y_value)
							settingToUse = Settings.SettingsMedicin2_range1_AOBChart + medicincntr * 4;
						else if (theEvent.amount < z_value)
							settingToUse = Settings.SettingsMedicin3_range1_AOBChart + medicincntr * 4;
						else 
							settingToUse = Settings.SettingsMedicin4_range1_AOBChart + medicincntr * 4;
						var fromTimeAndValueArrayCollection:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(Settings.getInstance().getSetting(settingToUse));
						if (theEvent.bolustype == ResourceManager.getInstance().getString('editmedicineventview','square')) {
							//split over 0.1 unit per injection
							var amountOfInjections:int = theEvent.amount / BOLUS_AMOUNT_FOR_SQUARE_WAVE_BOLUSSES;
							var intervalBetweenInjections:Number = theEvent.bolusDurationInMinutes / amountOfInjections;
							var injectionsCntr:int;
							var timeStampOfInjection:Number;
							for (injectionsCntr = 0;injectionsCntr < amountOfInjections;injectionsCntr++) {
								timeStampOfInjection = ((theEvent as TrackingViewElement).timeStamp + injectionsCntr * intervalBetweenInjections * 60 * 1000);
								if (timeStampOfInjection < time) {
									var percentage:Number = fromTimeAndValueArrayCollection.getValue((time - timeStampOfInjection)/1000);
									activeInsulin += BOLUS_AMOUNT_FOR_SQUARE_WAVE_BOLUSSES *  percentage / 100;
								} else 
									break;
							}
						} else {
							activeInsulin = theEvent.amount * fromTimeAndValueArrayCollection.getValue((time - (theEvent as TrackingViewElement).timeStamp)/1000) / 100;
						}
					} else {
						//there's a medicinevent found with type of insulin that has a not-enbled profile
					}
					medicincntr = 5;
				}
			}
			return activeInsulin;
		}
	}
}