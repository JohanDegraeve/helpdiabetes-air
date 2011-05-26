package databaseclasses
{
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	

	/**
	 * this is a meal event,<br>
	 * creation of a meal event, destroying a mealevent (? possible ?), modification of a meal event all affects database,<br>
	 * ie a database update or insertion will be done behind the scene. That's why MealEvent is part of package databaseclasses.<br>
	 * In general the methods do not handle database update errors. The classes will exist or be modified but in case a database update occurs, there's no method to inform the client
	 * <br>
	 * Also the selected Food Items are stored in here.<br>
	 */ 
	public class MealEvent
	{
		/**
		 * the mealType
		 */ 
		private var mealType:String;
		/**
		 * the insulineratio, if null then there was no insuline ratio for the period in which the meal was created or modified
		 */ 
		private var insulineRatio:Number;
		/**
		 * the correction factor, if null then there was no correction factor for the period in which the meal was created or modified
		 */ 
		private var correctionFactor:Number;
		private var mealeventId:Number;
		
		private var selectedFoodItems:ArrayCollection;
		
		/**
		 * mealEvent will be created and automatically inserted into the database<br>
		 * insulinRatio and correctionFactor can be null which means there's no settings for the defined period
		 */
		public function MealEvent(mealType:String, insulinRatio:Number, correctionFactor:Number) {
			this.mealType = mealType;
			this.insulineRatio = insulinRatio;
			mealeventId = new Number(Settings.getInstance().getSetting(Settings.SettingNEXT_MEAL_ID));
			selectedFoodItems = new ArrayCollection();
			
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
			Database.getInstance().createNewMealEvent(mealType,new Date().valueOf().toString(),insulinRatio,correctionFactor,dispatcher);
			Settings.getInstance().setSetting(Settings.SettingNEXT_MEAL_ID, mealeventId + 1);
			
			function mealEventCreationFailed (errorEvent:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				Settings.getInstance().setSetting(Settings.SettingNEXT_MEAL_ID, mealeventId);
				trace("Error while storing mealevent in database. MealEvent.as 0001");
			}
		}
		
		public function addSelectedFoodItem(selecedFoodItem:SelectedFoodItem):void {
			selectedFoodItems.addItem(selecedFoodItem);
			
		}
	}
}