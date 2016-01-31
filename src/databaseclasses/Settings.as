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

package databaseclasses
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.resources.ResourceManager;
	
	import model.ModelLocator;
	
	/**
	 * Each time a new settings is defined, an additional constant should be defined, with default value and the array must be extended.<br>
	 * The first constant is 0;<br>
	 * It's a singleton, at first creation, all settings will be intialized with default values.<br>
	 * Each time a new value is stored, the value will be written to the database. <br>
	 * All settings can be set and get , as string representation.<br>
	 * 
	 * Change made 16/04/2013, because i want to add more settings that can be synced, I added possiblity to create settings with id -100 to -1, these settings willb e synced <br>
	 * When adding a setting that needs to be synced, always go one lower.
	 */
	public class Settings
		
	{
		[ResourceBundle("editmedicineventview")]
		[ResourceBundle("editexerciseeventview")]
		[ResourceBundle("settingsmealprofilesview")]
		
		/** default values for active carbs on board, per range **/ 
		public static const Meal1_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal1_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal1_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal1_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal2_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal2_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal2_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal2_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal3_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal3_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal3_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal3_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal4_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal4_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal4_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal4_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal5_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal5_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal5_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal5_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal6_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal6_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal6_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal6_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal7_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal7_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal7_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal7_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal8_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal8_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal8_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal8_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal9_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal9_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal9_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal9_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal10_range_1_AOCChart_FactoryValue:String = "0:15-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal10_range_2_AOCChart_FactoryValue:String = "15:25-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal10_range_3_AOCChart_FactoryValue:String = "25:35-{carbs}-00:00>100-01:00>60-02:00>50";
		public static const Meal10_range_4_AOCChart_FactoryValue:String = "35:45-{carbs}-00:00>100-01:00>60-02:00>50";
		
		/** default values for active insulin on board, per range **/
		public static const Medicin1_range1_AOBChart_FactoryValue:String= "0:15-%-00:00>100-00:30>90-01:00>70-01:30>50-02:00>35-02:30>20-03:00>10-04:00>0";
		public static const Medicin1_range2_AOBChart_FactoryValue:String= "15:25-%-00:00>100-00:30>90-01:00>70-01:30>50-02:00>35-02:30>20-03:00>10-04:00>0";
		public static const Medicin1_range3_AOBChart_FactoryValue:String= "25:35-%-00:00>100-00:30>90-01:00>70-01:30>50-02:00>35-02:30>20-03:00>10-04:00>0";
		public static const Medicin1_range4_AOBChart_FactoryValue:String= "35:9999-%-00:00>100-00:30>90-01:00>70-01:30>50-02:00>35-02:30>20-03:00>10-04:00>0";
		public static const Medicin2_range1_AOBChart_FactoryValue:String= "0:15-%-00:00>100";
		public static const Medicin2_range2_AOBChart_FactoryValue:String= "15:25-%-00:00>100";
		public static const Medicin2_range3_AOBChart_FactoryValue:String= "25:35-%-00:00>100";
		public static const Medicin2_range4_AOBChart_FactoryValue:String= "35:9999-%-00:00>100";
		public static const Medicin3_range1_AOBChart_FactoryValue:String= "0:15-%-00:00>100";
		public static const Medicin3_range2_AOBChart_FactoryValue:String= "15:25-%-00:00>100";
		public static const Medicin3_range3_AOBChart_FactoryValue:String= "25:35-%-00:00>100";
		public static const Medicin3_range4_AOBChart_FactoryValue:String= "35:9999-%-00:00>100";
		public static const Medicin4_range1_AOBChart_FactoryValue:String= "0:15-%-00:00>100";
		public static const Medicin4_range2_AOBChart_FactoryValue:String= "15:25-%-00:00>100";
		public static const Medicin4_range3_AOBChart_FactoryValue:String= "25:35-%-00:00>100";
		public static const Medicin4_range4_AOBChart_FactoryValue:String= "35:9999-%-00:00>100";
		public static const Medicin5_range1_AOBChart_FactoryValue:String= "0:15-%-00:00>100";
		public static const Medicin5_range2_AOBChart_FactoryValue:String= "15:25-%-00:00>100";
		public static const Medicin5_range3_AOBChart_FactoryValue:String= "25:35-%-00:00>100";
		public static const Medicin5_range4_AOBChart_FactoryValue:String= "35:9999-%-00:00>100";
		
		/**
		 * default values for nightscout api secret and url
		 */
		public static const NightScoutDefaultAPISECRET:String = "API_SECRET";
		public static const NightScoutDefaultWebsiteURL:String = "your-website.azurewebsites.net";

		
		/** EXTEND LIST OF CONSTANTS IN CASE NEW SETTING NEEDS TO BE DEFINED  */

		/**
		 * maximum duration of insulin in seconds<br>
		 * will be adapted here as soon as one of the profiles gets changed<br>
		 * not really necessary to synchronize it because it will be udpated here as soon as one of the insulin profiles gets updated
		 */
		public static const SettingsMaximumInsulinDurationInSeconds:int = -88;
		/** extended functions active or not
		 */
		public static const SettingsExtendedFunctionsActive:int = -87;
		/** Descriptions of the meal graphs **/
		public static const SettingsMeal1GraphDescription:int = -86;
		public static const SettingsMeal2GraphDescription:int = -85;
		public static const SettingsMeal3GraphDescription:int = -84;
		public static const SettingsMeal4GraphDescription:int = -83;
		public static const SettingsMeal5GraphDescription:int = -82;
		public static const SettingsMeal6GraphDescription:int = -81;
		public static const SettingsMeal7GraphDescription:int = -80;
		public static const SettingsMeal8GraphDescription:int = -79;
		public static const SettingsMeal9GraphDescription:int = -78;
		public static const SettingsMeal10GraphDescription:int = -77;
		
		/** is meal aob calculation active or not ? **/
		public static const SettingsMeal1_AOBActive:int = -76;
		public static const SettingsMeal2_AOBActive:int = -75;
		public static const SettingsMeal3_AOBActive:int = -74;
		public static const SettingsMeal4_AOBActive:int = -73;
		public static const SettingsMeal5_AOBActive:int = -72;
		public static const SettingsMeal6_AOBActive:int = -71;
		public static const SettingsMeal7_AOBActive:int = -70;
		public static const SettingsMeal8_AOBActive:int = -69;
		public static const SettingsMeal9_AOBActive:int = -68;
		public static const SettingsMeal10_AOBActive:int = -67;
		
		/** charts for meal active  on board, per range **/
		public static const SettingsMeal1_range1_AOBChart:int = -66;
		public static const SettingsMeal1_range2_AOBChart:int = -65;
		public static const SettingsMeal1_range3_AOBChart:int = -64;
		public static const SettingsMeal1_range4_AOBChart:int = -63;
		public static const SettingsMeal2_range1_AOBChart:int = -62;
		public static const SettingsMeal2_range2_AOBChart:int = -61;
		public static const SettingsMeal2_range3_AOBChart:int = -60;
		public static const SettingsMeal2_range4_AOBChart:int = -59;
		public static const SettingsMeal3_range1_AOBChart:int = -58;
		public static const SettingsMeal3_range2_AOBChart:int = -57;
		public static const SettingsMeal3_range3_AOBChart:int = -56;
		public static const SettingsMeal3_range4_AOBChart:int = -55;
		public static const SettingsMeal4_range1_AOBChart:int = -54;
		public static const SettingsMeal4_range2_AOBChart:int = -53;
		public static const SettingsMeal4_range3_AOBChart:int = -52;
		public static const SettingsMeal4_range4_AOBChart:int = -51;
		public static const SettingsMeal5_range1_AOBChart:int = -50;
		public static const SettingsMeal5_range2_AOBChart:int = -49;
		public static const SettingsMeal5_range3_AOBChart:int = -48;
		public static const SettingsMeal5_range4_AOBChart:int = -47;
		public static const SettingsMeal6_range1_AOBChart:int = -46;
		public static const SettingsMeal6_range2_AOBChart:int = -45;
		public static const SettingsMeal6_range3_AOBChart:int = -44;
		public static const SettingsMeal6_range4_AOBChart:int = -43;
		public static const SettingsMeal7_range1_AOBChart:int = -42;
		public static const SettingsMeal7_range2_AOBChart:int = -41;
		public static const SettingsMeal7_range3_AOBChart:int = -40;
		public static const SettingsMeal7_range4_AOBChart:int = -39;
		public static const SettingsMeal8_range1_AOBChart:int = -38;
		public static const SettingsMeal8_range2_AOBChart:int = -37;
		public static const SettingsMeal8_range3_AOBChart:int = -36;
		public static const SettingsMeal8_range4_AOBChart:int = -35;
		public static const SettingsMeal9_range1_AOBChart:int = -34;
		public static const SettingsMeal9_range2_AOBChart:int = -33;
		public static const SettingsMeal9_range3_AOBChart:int = -32;
		public static const SettingsMeal9_range4_AOBChart:int = -31;
		public static const SettingsMeal10_range1_AOBChart:int = -30;
		public static const SettingsMeal10_range2_AOBChart:int = -29;
		public static const SettingsMeal10_range3_AOBChart:int = -28;
		public static const SettingsMeal10_range4_AOBChart:int = -27;

		/** is medicin aob calculation active or not ? **/
		public static const SettingsMedicin1_AOBActive:int = -26;
		public static const SettingsMedicin2_AOBActive:int = -25;
		public static const SettingsMedicin3_AOBActive:int = -24;
		public static const SettingsMedicin4_AOBActive:int = -23;
		public static const SettingsMedicin5_AOBActive:int = -22;

		/** charts for medicin active insulin on board, per range **/
		public static const SettingsMedicin1_range1_AOBChart:int = -21;
		public static const SettingsMedicin1_range2_AOBChart:int = -20;
		public static const SettingsMedicin1_range3_AOBChart:int = -19;
		public static const SettingsMedicin1_range4_AOBChart:int = -18;
		public static const SettingsMedicin2_range1_AOBChart:int = -17;
		public static const SettingsMedicin2_range2_AOBChart:int = -16;
		public static const SettingsMedicin2_range3_AOBChart:int = -15;
		public static const SettingsMedicin2_range4_AOBChart:int = -14;
		public static const SettingsMedicin3_range1_AOBChart:int = -13;
		public static const SettingsMedicin3_range2_AOBChart:int = -12;
		public static const SettingsMedicin3_range3_AOBChart:int = -11;
		public static const SettingsMedicin3_range4_AOBChart:int = -10;
		public static const SettingsMedicin4_range1_AOBChart:int = -9;
		public static const SettingsMedicin4_range2_AOBChart:int = -8;
		public static const SettingsMedicin4_range3_AOBChart:int = -7;
		public static const SettingsMedicin4_range4_AOBChart:int = -6;
		public static const SettingsMedicin5_range1_AOBChart:int = -5;
		public static const SettingsMedicin5_range2_AOBChart:int = -4;
		public static const SettingsMedicin5_range3_AOBChart:int = -3;
		public static const SettingsMedicin5_range4_AOBChart:int = -2;
		/**
		 * correction factor string
		 */
		public static const SettingsCorrectionFactor:int = -1;
		/**
		 * the meal id where the last fooditem was stored
		 */ 
		public  static const SettingLAST_MEAL_ID:int = 0; 
		/**
		 * the time in milliseconds since midnight January 1, 1970, universal time, when the last fooditem was added
		 */ 
		public static const SettingTIME_OF_LAST_MEAL_ADDITION:int = 1;
		/**
		 * not used anymore
		 */
		internal static const SettingNEXT_MEALEVENT_ID:int=2;
		/**
		 * creationtimestamp of the last event that was uploaded to google excel logbook
		 */
		public static const SettingLastUploadedEventTimeStamp:int=3;
		/**
		 * insulinratio breakfast, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_BREKFAST:int=4;
		/**
		 * insulinratio lunch, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_LUNCH:int=5;
		/**
		 * insulinratio snack, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_SNACK:int=6;
		/**
		 * insulinratio supper, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_SUPPER:int=7;
		/**
		 * switch time breakfast to lunch, local time
		 */
		public static const SettingBREAKFAST_UNTIL: int =  8;
		/**
		 * switch time lunch to snack, local time
		 */
		public static const SettingLUNCH_UNTIL:int = 9;
		/**
		 * switch time snack to supper , , local time
		 */
		public static const SettingSNACK_UNTIL:int = 10;
		/**
		 * 
		 */
		public static const SettingNotUsedAnyMore:int=11
		/**
		 * id of last bloodglucose event
		 */
		public static const SettingLAST_BLOODGLUCOSE_EVENT_ID:int = 12;
		/**
		 * maximum time difference between a meal and the last bloodglucose event for calculating the correction factor<br>
		 * in seconds 
		 */
		public static const SettingMAX_TIME_DIFFERENCE_LATEST_BGEVENT_AND_START_OF_MEAL:int= 13;
		/**
		 * unit to use for bloodglucose values<br>
		 * initial value = mgperdl 
		 */
		public static const SettingsBLOODGLUCOSE_UNIT:int = 14;
		
		/**
		 * the target bloodglucoselevel to use for applying the correction factor
		 */
		public static const SettingsTARGET_BLOODGLUCOSELEVEL:int = 15;
		/**
		 * what is the important value for the user : carbs, kilocalories, fat or protein
		 */
		public static const SettingsIMPORTANT_VALUE_FOR_USER:int = 16;
		
		/**
		 * the string for the first insulin type , default value taken from resources
		 */
		public static const SettingsInsulinType1:int = 17;
		/**
		 * the string for the second insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType2:int = 18;
		/**
		 * the string for the third insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType3:int = 19;
		/**
		 * the string for the fourth insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType4:int = 20;
		/**
		 * the string for the fifth insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType5:int = 21;
		
		/**
		 * denotes the default medicin, value is int 17, 18, 19, 20 or 21, denoting type 1, ... 5 respectively<br>
		 * default value = 17
		 */
		public static const SettingsDefaultMedicin:int = 22;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType1:int = 23;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType2:int = 24;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType3:int = 25;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType4:int = 26;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType5:int = 27;
		/**
		 * denotes the default exercise, value is int 23, 24, 25, 26 or 27, denoting type 1, ... 5 respectively<br>
		 * default value = 23
		 */
		public static const SettingsDefaultExercise:int = 28;
		/**
		 * maximum size of trackingview, in days, default value  = 30;
		 */
		public static const SettingsMAXTRACKINGSIZE:int = 29;
		/**
		 * localeChain to be used for choosing translations. The locale chain is a string here <br>
		 * Example if localeChain = ["en_US","nl_NL"], then the setting here is "en_US,nl_NL"
		 */
		public static const SettingsLOCALECHAIN_asString:int = 30;
		/**
		 * to maintain the first startup of the app, never is never started up before
		 */
		public static const SettingsFirstStartUp:int=31;
		
		/** help setings **/
		/** if false, help text will not be shown **/
		public static const SettingsHelpTextAddFoodItemViewSelectUnitButton:int=32;
		public static const SettingsHelpTextAddFoodItemViewSelectMealButton:int=33;
		public static const SettingsHelpTextAddFoodItemViewAmountButtonsWhenComingFromFoodCounterView:int=34;
		public static const SettingsHelpTextAddFoodItemViewAmountButtonsWhenComingFromTrackingView:int=35;
		public static const SettingsHelpTextAddFoodItemViewOkButton:int=36;
		public static const SettingsHelpTextChangeMealDateAndTimeViewButtons:int=37;
		public static const SettingsHelpTextAddFoodItemViewTrashButton:int=38;
		public static const SettingsHelpTextEditMealEventViewEditSelectedItem:int=39;
		public static const SettingsHelpTextEditBGEventViewChangeAmount:int=40;
		public static const SettingsHelpTextEditBGEventViewChangeDateAndTime:int=41;
		public static const SettingsHelpTextEditMedicinEventViewChangeMedicinType:int=42;
		public static const SettingsHelpTextEditMedicinEventViewChangeAmount:int=43;
		public static const SettingsHelpTextEditExerciseEventViewChangeExerciseType:int=44;
		public static const SettingsHelpTextBolusCalculationViewChangeCarbRatio:int=45;
		public static const SettingsHelpTextMealTimesViewChangeMealTimes:int=46;
		public static const SettingsHelpTextMedicinViewChangeMedicinType:int=47;
		public static const SettingsHelpTextExerciseViewChangeMedicinType:int=48;
		public static const SettingsHelpTextDatabaseViewChangeStorage:int=49;
		public static const SettingsHelpTextEditMedicinEventViewOkButton:int=50;
		public static const SettingsHelpTextEditExerciseEventViewOkButton:int=51;
		public static const SettingsHelpTextEditBGEventViewOkButton:int=52;
		public static const SettingsHelpTextEditMealEventViewEditDateAndTime:int=53;
		public static const SettingsHelpTextOwnFoodItemView:int=54;
		public static const SettingsHelpTextTrackingViewSearchButton:int=55;
		public static const SettingsHelpTextTrackingView1:int=56;
		public static const SettingsHelpTextTrackingViewUpButton:int=57;
		public static const SettingsHelpTextTrackingViewDownButton:int=58;
		public static const SettingsHelpTextTrackingViewCancelButton:int=59;
		public static const SettingsHelpTextFoodCounterViewSearchText:int=60;
		public static const SettingsHelpTextFoodCounterViewSearchButton:int=61;
		public static const SettingsHelpTextFoodCounterViewCancelButton:int=62;
		public static const SettingsHelpTextMedicinProfile:int=63;
		public static const SettingsHelpTextViewBolusCalculationDetails:int=64;
		public static const SettingsHelpTextEditTrackingEvent:int=65;
		public static const SettingsHelpTextActiveInsulinInt:int=66;
		public static const SettingsHelpTextEnableActiveInsulinCalculationInInsulinSettingsView:int=67;
		public static const SettingsTimeStampOfLastTimeSplashScreenWasShownForLongTime:int=68;
		public static const SettingsSelectedOrientation:int=69;//0 = portrait, 1 = landscape, 2 = automatic, 3 = let app decide
		public static const SettingsNightScoutAPISECRET:int=70;
		public static const SettingsNightScoutWebsiteURL:int=71;
		public static const SettingsNightScoutHashedAPISecret:int=72;
		public static const SettingsHelpText73:int=73;
		public static const SettingsHelpText74:int=74;
		public static const SettingsHelpText75:int=75;
		public static const SettingsHelpText76:int=76;
		public static const SettingsHelpText77:int=77;
		public static const SettingsHelpText78:int=78;
		public static const SettingsHelpText79:int=79;
		public static const SettingsHelpText80:int=80;
		public static const SettingsHelpText81:int=81;
		public static const SettingsHelpText82:int=82;
		public static const SettingsHelpText83:int=83;
		public static const SettingsHelpText84:int=84;
		public static const SettingsHelpText85:int=85;
		public static const SettingsHelpText86:int=86;
		public static const SettingsHelpText87:int=87;
		public static const SettingsHelpText88:int=88;
		public static const SettingsHelpText89:int=89;
		public static const SettingsHelpText90:int=90;
		public static const SettingsHelpText91:int=91;
		public static const SettingsHelpText92:int=92;
		public static const SettingsHelpText93:int=93;
		public static const SettingsHelpText94:int=94;
		public static const SettingsHelpText95:int=95;
		public static const SettingsHelpText96:int=96;
		public static const SettingsHelpText97:int=97;
		public static const SettingsHelpText98:int=98;
		public static const SettingsHelpText99:int=99;
		public static const SettingsHelpText100:int=100;
		/**
		 * access_token for Google sync 
		 */
		public static const SettingsAccessToken:int=101;
		/**
		 * refresh_token for Google sync
		 */
		public static const SettingsRefreshToken:int=102;
		public static const SettingsLastGoogleSyncTimeStamp:int=103;
		/**
		 * index to array of column names in the foodtable in google docs, index points to the next column that needs to be created<br>
		 * 0 = first one , 1 = second, ... if > size of array of column names, then all column names are created 
		 */
		public static const SettingsNextColumnToAddInFoodTable:int=104;
		/**
		 * A user may have installed this app on several devices. Only one device will upload the foodtable to google docs.<br>
		 * This setting indicates if the foodtable has been or is being created by this instance. 
		 */
		public static const SettingsIMtheCreateorOfGoogleExcelFoodTable:int=105;
		/**
		 * index to fooditems table in the foodtable in google docs, index points to the next row that needs to be inserted<br>
		 * 0 = first one , 1 = second, ... if > size of foodtable in the database installed here, then all rows are uploaded<br>
		 * Once upload is finished, this value may not match anymore, because user may have downloaded a new database with a different size,
		 * therefor the next setting is also important
		 */
		public static const SettingsNextRowToAddInFoodTable:int=106;
		public static const SettingsAllFoodItemsUploadedToGoogleExcel:int=107;
		/**
		 * index to array of column names in the logbook in google docs, index points to the next column that needs to be created<br>
		 * 0 = first one , 1 = second, ... if > size of array of column names, then all column names are created 
		 */
		public static const SettingsNextColumnToAddInLogBook:int=108;
		/**
		 * day of the month (ie 1..31), where last complete sync was done. -1 means not yet done. 
		 **/
		public static const SettingsDayOfLastCompleteGoogleSync:int=109;
		
		/**
		 * used in blood glucose graph, how many timestamps will be calculated.
		 */public static const SettingsAmountOfCalculationsInBloodGlucoseGraph:int = 110;
		/**
		 * SettingsDayOfLastCompleteNightScoutSync day of the month (ie 1..31), where last complete sync was done. -1 means not yet done. 
		 */
		public static const SettingsDayOfLastCompleteNightScoutSync:int = 111;
		public static const SettingsLastNightScoutSyncTimeStamp:int=112;
		
		/** EXTEND ARRAY WITH DEFAULT VALUES IN CASE NEW SETTING NEEDS TO BE DEFINED */
		private var settings:Array = [
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"14400",//maximum duration insulin in seconds - default values is 4 hours, so 
			"false",// extended functions active or not
			"",//meal Type 1
			"",//meal Type 2
			"",//meal Type 3
			"",//meal Type 4
			"",//meal Type 5
			"",//meal Type 6
			"",//meal Type 7
			"",//meal Type 8
			"",//meal Type 9
			"",//meal Type 10
			"false",//carbs 1 aob active or not
			"false",//carbs 2 aob active or not
			"false",//carbs 3 aob active or not
			"false",//carbs 4 aob active or not
			"false",//carbs 5 aob active or not
			"false",//carbs 1 aob active or not
			"false",//carbs 2 aob active or not
			"false",//carbs 3 aob active or not
			"false",//carbs 4 aob active or not
			"false",//carbs 5 aob active or not
			Meal1_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal1_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal1_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal1_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal2_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal2_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal2_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal2_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal3_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal3_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal3_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal3_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal4_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal4_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal4_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal4_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal5_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal5_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal5_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal5_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal6_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal6_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal6_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal6_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal7_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal7_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal7_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal7_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal8_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal8_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal8_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal8_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal9_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal9_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal9_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal9_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal10_range_1_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal10_range_2_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal10_range_3_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			Meal10_range_4_AOCChart_FactoryValue.replace("{carbs}",ResourceManager.getInstance().getString('general','gram_of_carbs_short')),
			"false",//medicin 1 aob active or not
			"false",//medicin 2 aob active or not
			"false",//medicin 3 aob active or not
			"false",//medicin 4 aob active or not
			"false",//medicin 5 aob active or not
			Medicin1_range1_AOBChart_FactoryValue,//		public static const SettingsMedicin1_range1_AOBChart:int = -21;
			Medicin1_range2_AOBChart_FactoryValue,//		public static const SettingsMedicin1_range2_AOBChart:int = -20;
			Medicin1_range3_AOBChart_FactoryValue,//		public static const SettingsMedicin1_range3_AOBChart:int = -19;
			Medicin1_range4_AOBChart_FactoryValue,//		public static const SettingsMedicin1_range4_AOBChart:int = -18;
			Medicin2_range1_AOBChart_FactoryValue,//		public static const SettingsMedicin2_range1_AOBChart:int = -17;
			Medicin2_range2_AOBChart_FactoryValue,//		public static const SettingsMedicin2_range2_AOBChart:int = -16;
			Medicin2_range3_AOBChart_FactoryValue,//		public static const SettingsMedicin2_range3_AOBChart:int = -15;
			Medicin2_range4_AOBChart_FactoryValue,//		public static const SettingsMedicin2_range4_AOBChart:int = -14;
			Medicin3_range1_AOBChart_FactoryValue,//		public static const SettingsMedicin3_range1_AOBChart:int = -13;
			Medicin3_range2_AOBChart_FactoryValue,//		public static const SettingsMedicin3_range2_AOBChart:int = -12;
			Medicin3_range3_AOBChart_FactoryValue,//		public static const SettingsMedicin3_range3_AOBChart:int = -11;
			Medicin3_range4_AOBChart_FactoryValue,//		public static const SettingsMedicin3_range4_AOBChart:int = -10;
			Medicin4_range1_AOBChart_FactoryValue,//		public static const SettingsMedicin4_range1_AOBChart:int = -9;
			Medicin4_range2_AOBChart_FactoryValue,//		public static const SettingsMedicin4_range2_AOBChart:int = -8;
			Medicin4_range3_AOBChart_FactoryValue,//		public static const SettingsMedicin4_range3_AOBChart:int = -7;
			Medicin4_range4_AOBChart_FactoryValue,//		public static const SettingsMedicin4_range4_AOBChart:int = -6;
			Medicin5_range1_AOBChart_FactoryValue,//		public static const SettingsMedicin5_range1_AOBChart:int = -5;
			Medicin5_range2_AOBChart_FactoryValue,//		public static const SettingsMedicin5_range2_AOBChart:int = -4;
			Medicin5_range3_AOBChart_FactoryValue,//		public static const SettingsMedicin5_range3_AOBChart:int = -3;
			Medicin5_range4_AOBChart_FactoryValue,//		public static const SettingsMedicin5_range4_AOBChart:int = -2;
			"",//correctiefactor initialized in constructor
			//values are splitted by -
			//first values,before the first - is only used for medicin and food curves, not for correction factors
			//it is something like for example 1:10, meaning curve valid for amounts between 1 and 10
			//for coreciton factor, we set something like 0:0 as first value
			//the first value in the first range should always be 0, the second value in the last range should be 9999, actually first
			//actually first value of one setting should be equal to second value of previous setting
			//
			// mmol/l-00:00>1.5  betekent correctiefactor 1.5 van 00:00 tot 23:59, eerste veld is de eenheid
			// mg/dl-00:00>1.5-08:00>2.3-20:00>1.5 betekent 1.5 tussen 00:00 en 08:00 en 2.3 tussen 8 en 20 en vanaf 20 1.5
			"none",// index 100 , corresponds to setting with value 0, initially there will be no meal too which the last  fooditem has been added
			new Date(0).valueOf().toString(), //midnight January 1, 1970, universal time,
			"1", //the first meal id to be used
			"1", //first selected item id to be used
			"0", //insulin ratio breakfast
			"0", //lunch
			"0", //snack
			"0", //supper
			"37800000", // January 1, 1970, 10h30 Hr in ms, gmt time,
			"55800000", // January 1, 1970, 15h30 Hr in ms, gmt time,
			"61200000", // January 1, 1970, 17 Hr in ms, gmt time,
			"0", //correction factor - not used anymore, this is now in SettingsCorrectionFactor
			"0", //the first blood glucose event id to be used
			"999999", //in get setting if 999999 , then 900 will be returned which corresponds to 15 minutes
			"mgperdl", //unit for bloodglucose metering, this value must be known in locale/general.properties
			"120",//targetbloodglucoselevel
			"carbs",//possible values are "carbs", "protein", "fat", "kilocalories"
			"insulin type 1 defined in constructor",
			"insulin type 2 defined in constructor",
			"insulin type 3 defined in constructor",
			"insulin type 4 defined in constructor",
			"insulin type 5 defined in constructor",
			"17",//default insulin type, meaning insulin type 1
			"exercise type 1 defined in constructor",
			"exercise type 2 defined in constructor",
			"exercise type 3 defined in constructor",
			"exercise type 4 defined in constructor",
			"exercise type 5 defined in constructor",
			"23",//default exercise type, meaning exercise type 1
			"30",//default length of trackingview, in days
			"en_US,nl_NL,fr_FR",//just a default value,  will be overwrittin in constructor
			"firsttartuptime defined in constructor",//firststartuptime, will be set in constructor
			"true",//SettingsAddFoodItemViewSelectUnitButton
			"true",//SettingsHelpTextAddFoodItemViewSelectMealButton
			"true",//SettingsHelpTextAddFoodItemViewAmountButtons
			"true",//SettingsHelpTextAddFoodItemViewAmountButtonsWhenComingFromTrackingView
			"true",//SettingsHelpTextAddFoodItemViewOkButton
			"true",
			"true",//SettingsHelpTextAddFoodItemViewTrashButton
			"true",//SettingsHelpTextEditMealEventViewEditSelectedItem
			"true",//SettingsHelpTextEditBGEventViewChangeAmount
			"true",//SettingsHelpTextEditBGEventViewChangeDateAndTime
			"true",//SettingsHelpTextEditMedicinEventViewChangeMedicinType
			"true",//SettingsHelpTextEditMedicinEventViewChangeAmount
			"true",//SettingsHelpTextEditExerciseEventViewChangeMedicinType
			"true",//SettingsHelpTextBolusCalculationViewChangeCarbRatio
			"true",//SettingsHelpTextMealTimesViewChangeMealTimes
			"true",//SettingsHelpTextMedicinViewChangeMedicinType
			"true",//SettingsHelpTextExerciseViewChangeMedicinType
			"true",//SettingsHelpTextDatabaseViewChangeStorage
			"true",//ok buttons for medicin event, exercise event and bloodglucoseevent
			"true",
			"true",
			"true",//number 53
			"true",//SettingsHelpTextOwnFoodItemView, 54
			"true",//55
			"true",
			"true",
			"true",
			"true",//59
			"true",//SettingsHelpTextFoodCounterViewSearchField
			"true",//SettingsHelpTextFoodCounterViewSearchButton
			"true",//SettingsHelpTextFoodCounterViewCancelButton
			"true",//SettingsHelpTextMedicinProfile
			"true",//SettingsHelpTextViewBolusCalculationDetails
			"true",//SettingsHelpTextEditTrackingEvent
			"true",//SettingsHelpTextActiveInsulinInt
			"true",//SettingsHelpTextEnableActiveInsulinCalculationInInsulinSettingsView
			"0",//SettingsTimeStampOfLastTimeSplashScreenWasShownForLongTime, 0 means never been set this value
			"3",//SettingsSelectedOrientation 0 = portrait, 1 = landscape, 2 = automatic, 3 = let app decide
			NightScoutDefaultAPISECRET, 
			NightScoutDefaultWebsiteURL,
			"",//hashed api secret
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",
			"true",//last helptext
			"",//default access token
			"",//default refresh token
			"0",//lastgooglesynctimestamp
			"0",//index to column names for google excel foodtable
			"false",//creator of foodtable on google excel
			"0",//SettingsNextRowToAdd
			"false",//all fooditmes uploaded or not
			"0",//SettingsNextColumnToAddInLogBook
			"-1",//SettingsDayOfLastCompleteGoogleSync
			"100",//SettingsAmountOfCalculationsInBloodGlucoseGraph
			"-1",//SettingsDayOfLastCompleteNightScoutSync
			"0"//lastnightscoutsynctimestamp
		];
		
		/** array with lastmodifiedtimestamp<br> 
		 * initialisation in the same way as settingsitself<br>
		 */
		private var settingsLastModifiedTimeStamp:Array;
		
		private static var instance:Settings = new Settings();
		
		public function Settings()
		{
			if (instance != null) {
				throw new Error("Settings class can only be accessed through Settings.getInstance()");	
			}
			//all settings are being set to initial values, be aware that in case there are already settings in the database
			//then the settings array will be reset during database opening.
			//There's already a database if it's not the first startup
			// in other words, if this is the first startup, then these are the values
			settings[100 + SettingsInsulinType1] = ResourceManager.getInstance().getString('editmedicineventview','insulintype1');
			settings[100 + SettingsInsulinType2] = ResourceManager.getInstance().getString('editmedicineventview','insulintype2');
			settings[100 + SettingsInsulinType3] = ResourceManager.getInstance().getString('editmedicineventview','insulintype3');
			settings[100 + SettingsInsulinType4] = ResourceManager.getInstance().getString('editmedicineventview','insulintype4');
			settings[100 + SettingsInsulinType5] = ResourceManager.getInstance().getString('editmedicineventview','insulintype5');
			settings[100 + SettingsExerciseType1] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype1');
			settings[100 + SettingsExerciseType2] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype2');
			settings[100 + SettingsExerciseType3] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype3');
			settings[100 + SettingsExerciseType4] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype4');
			settings[100 + SettingsExerciseType5] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype5');
			settings[100 + SettingsFirstStartUp] = (new Date()).valueOf().toString();
			settings[100 + SettingsCorrectionFactor] = "0:0-" /* first values not used in cf */ + ResourceManager.getInstance().getString('general','mgperdl') ; 
	
			settings[100 + SettingsMeal1GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype1description');
			settings[100 + SettingsMeal2GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype2description');
			settings[100 + SettingsMeal3GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype3description');
			settings[100 + SettingsMeal4GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype4description');
			settings[100 + SettingsMeal5GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype5description');
			settings[100 + SettingsMeal6GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype6description');
			settings[100 + SettingsMeal7GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype7description');
			settings[100 + SettingsMeal8GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype8description');
			settings[100 + SettingsMeal9GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype9description');
			settings[100 + SettingsMeal10GraphDescription] = ResourceManager.getInstance().getString('settingsmealprofilesview','mealtype10description');
			settings[100 + SettingsLOCALECHAIN_asString] = ResourceManager.getInstance().getString('general','localechainasstring');
			
			settingsLastModifiedTimeStamp = new Array(settings.length);
			for (var i:int = 0;i < settingsLastModifiedTimeStamp.length;i++)
				settingsLastModifiedTimeStamp[i] = new Number(0);
			
			instance = this;
		}
		
		public static function getInstance():Settings {
			if (instance == null) instance = new Settings();
			return instance;
		}
		
		/**
		 * get the setting specified by the Setting id
		 */
		public function getSetting(settingId:int):String {
			if (settingId == SettingMAX_TIME_DIFFERENCE_LATEST_BGEVENT_AND_START_OF_MEAL) {
				if (settings[100 + settingId] == "999999")
					return "900";
			}
			//if it's getting SettingsSelectedOrientation, then first an attempt will be made to open the database
			//but without creating it
			//because getSetting for SettingsSelectedOrientation happens before the database is opened, so it could be that the 
			//value here is not yet updated with value in the database
			if (settingId == SettingsSelectedOrientation) {
				var returnValue:String = Database.getInstance().getSetting(SettingsSelectedOrientation);
				if (returnValue != "null") {
					return returnValue;
				}
			}
			return settings[100 + settingId];
		}
		
		/**
		 * get the lastmodifiedtimestamp for the setting specified by the Setting id
		 */
		public function getSettingLastModifiedTimeStamp(settingId:int):Number {
			return settingsLastModifiedTimeStamp[100 + settingId];
		}
		
		/**
		 * Set the setting specified by the setting id, database will also be updated asynchronously<br>
		 * <br>
		 * if SettingsCorrectionFactor is changed, then this function will update the correction factor for all mealevents in thre trackinglist
		 * <br>
		 * if lastModifiedTimeStamp == null then current date and time are used
		 */
		public function setSetting(settingId:int, newValue:String,lastModifiedTimeStamp:Number = Number.NaN):void {
			settingId += 100;//100 extra settings added in front of first
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
			dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,settingInsertionSuccess);
			
			var oldValue:String = settings[settingId];
			var oldLastModifiedTimeStamp:Number = settingsLastModifiedTimeStamp[settingId] ;
			
			if (isNaN(lastModifiedTimeStamp))
				lastModifiedTimeStamp = (new Date()).valueOf();
			settingsLastModifiedTimeStamp[settingId] = lastModifiedTimeStamp; 
			
			settings[settingId] = newValue;
			
			Database.getInstance().updateSetting(settingId, newValue, lastModifiedTimeStamp, dispatcher);
			
			function settingInsertionFailure(se:Event):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,settingInsertionSuccess);
				settings[settingId] = oldValue;
				settingsLastModifiedTimeStamp[settingId] = oldLastModifiedTimeStamp;
			}
			
			function settingInsertionSuccess(se:Event):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,settingInsertionSuccess);
				
				//update all mealevents
				//	 NOG AANPASSEN, ENKEL IN DIEN SETTING IS CORRECTIONFACTORSETTING
				ModelLocator.getInstance().resetCorrectionFactorsInMeals(new Date());
				
				//if it's a medicinprofile then update maxium duration
				if (settingId >= SettingsMedicin1_range1_AOBChart + 100 && settingId <= SettingsMedicin5_range4_AOBChart + 100) {
					var highestValueInSeconds:Number = new Number(0);
					for (var cntr:int = SettingsMedicin1_range1_AOBChart;cntr <= SettingsMedicin5_range4_AOBChart;cntr++) {
						var settingAsString:String = getSetting(cntr);
						//"0:15-%-00:00>100-00:30>90-01:00>70-01:30>50-02:00>35-02:30>20-03:00>10-04:00>0";
						var splittedSettingString:Array = settingAsString.split("-");
						var firstPieceWithPercentageValueZero:String;// = splittedSettingString[splitted.length - 1];
						var cntr27:int = 2;
						while (cntr27 < splittedSettingString.length) {
							firstPieceWithPercentageValueZero = splittedSettingString[cntr27];
							if (new Number((firstPieceWithPercentageValueZero.split(">")[1]) == 0))
								cntr27 = splittedSettingString.length;
							else
								cntr27++;
						}
						splittedSettingString = firstPieceWithPercentageValueZero.split(">");
						firstPieceWithPercentageValueZero = splittedSettingString[0];//it's actually the first pice
						splittedSettingString = firstPieceWithPercentageValueZero.split(":");
						var firstpiece:String = splittedSettingString[0];
						firstPieceWithPercentageValueZero = splittedSettingString[1];
						var durationInSeconds:Number = (new Number(firstpiece)) * 3600 + (new Number(firstPieceWithPercentageValueZero)) * 60;
						if (durationInSeconds > highestValueInSeconds)
							highestValueInSeconds = durationInSeconds;
					}
					setSetting(SettingsMaximumInsulinDurationInSeconds,highestValueInSeconds.toString(),(new Date()).valueOf());
				}
			}
		}
		
		/**
		 * get the number of settings
		 */
		public function getNumberOfSettings():Number {
			return settings.length;
		}
		
		public function setSettingWithoutDatabaseUpdate(settingId:int, newValue:String, lastModifiedTimeStamp:Number = Number.NaN):void {
			if (isNaN(lastModifiedTimeStamp))
				lastModifiedTimeStamp = (new Date()).valueOf();
			
			settings[settingId + 100] = newValue;
			settingsLastModifiedTimeStamp[settingId + 100] = lastModifiedTimeStamp;
		}
		
		private function getAmountOfSettings():int {
			return settings.length;
		}
	}
}