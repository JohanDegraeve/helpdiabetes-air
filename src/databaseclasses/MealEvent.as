package databaseclasses
{
	/**
	 * this is a meal event,
	 * creation of a meal event, destroying a mealevent (? possible ?), modification of a meal event all affects database,
	 * ie a database update or insertion will be done behind the scene. That's why MealEvent is part of package databaseclasses.
	 * In general the methods do not handle database update errors. The classes will exist or be modified but in case a database update occurs, there's no method to inform the client
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
		
		/**
		 * mealEvent will be created and automatically inserted into the database
		 * insulinRatio and correctionFactor can be null which means there's no settings for the defined period
		 */
		public function MealEvent(mealType:String, insulinRatio:Number, correctionFactor:Number){
			this.mealType = mealType;
			this.insulineRatio = insulinRatio;
			mealeventId = new Number(Settings.getInstance().getSetting(Settings.SettingNEXT_MEAL_ID));
			Database.getInstance().createNewMealEvent(mealType,new Date().valueOf().toString(),insulinRatio,correctionFactor,dispatcher);
		}
	}
}