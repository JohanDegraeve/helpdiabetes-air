package services
{
	import com.distriqt.extension.dialog.Dialog;
	import com.distriqt.extension.dialog.DialogView;
	import com.distriqt.extension.dialog.builders.AlertBuilder;
	import com.distriqt.extension.dialog.events.DialogViewEvent;
	import com.distriqt.extension.dialog.objects.DialogAction;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	import distriqtkey.DistriqtKey;
	
	import events.DialogServiceEvent;
	
	public class DialogService extends EventDispatcher
	{
		private static var _instance:DialogService = new DialogService();
		
		public static function get instance():DialogService
		{
			return _instance;
		}
		
		private static var initialStart:Boolean = true;
		private static var dialogViews:ArrayCollection;
		private static var dialogViewsMaxDurations:ArrayCollection;
		/**
		 * the dialogview that is currently open, null if none is open 
		 */
		private static var openDialogView:DialogView;
		private static var maxDurationTimer:Timer;
		
		private static var _isInitiated:Boolean = false;
		
		public static function get isInitiated():Boolean
		{
			return _isInitiated;
		}
		
		
		public function DialogService()
		{
			if (_instance != null) {
				throw new Error("DialogService class  constructor can not be used");	
			}
		}
		
		public static function init(stage:Stage):void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			Dialog.init(DistriqtKey.distriqtKey);
			Dialog.service.root = stage;
			dialogViews = new ArrayCollection();
			dialogViewsMaxDurations = new ArrayCollection();
			openDialogView = null;
			
			
			_isInitiated = true;
			_instance.dispatchEvent(new DialogServiceEvent(DialogServiceEvent.DIALOG_SERVICE_INITIATED_EVENT));
		}
		
		/**
		 * if maxDurationInSeconds specified then the dialog will be closed after the specified time
		 */
		public static function addDialog(dialogView:DialogView, maxDurationInSeconds:Number = Number.NaN):void {
			if (openDialogView != null) {
				dialogViewsMaxDurations.addItem(maxDurationInSeconds);
				//dialog will be processed as soon as the dialog that is currently open is closed again
			} else {
				processNewDialog(dialogView, maxDurationInSeconds);
			}
		}
		
		private static function maxDurationReached(event:Event = null):void {
			openDialogView.dispose();
			openDialogView = null;
			if (dialogViews.length > 0) {
				var dialogViewToShow:DialogView = dialogViews.getItemAt(0) as DialogView;
				dialogViews.removeItemAt(0);
				var maxDuration:Number = dialogViewsMaxDurations.getItemAt(0) as Number;
				dialogViewsMaxDurations.removeItemAt(0);
				processNewDialog(dialogViewToShow, maxDuration);
			}
		}
		
		private static function processNewDialog(dialogView:DialogView, maxDurationInSeconds:Number):void {
			dialogView.addEventListener(DialogViewEvent.CLOSED, dialogViewClosed);
			//dialogView.addEventListener(DialogViewEvent.CANCELLED, dialogViewClosed);
			dialogView.show();
			openDialogView = dialogView;
			if (!isNaN(maxDurationInSeconds)) {
				if (maxDurationInSeconds > 0) {
					disableMaxDurationTimer();
					maxDurationTimer = new Timer(maxDurationInSeconds * 1000, 1);
					maxDurationTimer.addEventListener(TimerEvent.TIMER, maxDurationReached);
					maxDurationTimer.start();
				}
			}
		}
		
		private static function dialogViewClosed(event:DialogViewEvent):void {
			disableMaxDurationTimer();
			
			var alert:DialogView = DialogView(event.currentTarget);
			alert.dispose();
			openDialogView = null;
			if (dialogViews.length > 0) {
				var dialogViewToShow:DialogView = dialogViews.getItemAt(0) as DialogView;
				dialogViews.removeItemAt(0);
				var maxDuration:Number = dialogViewsMaxDurations.getItemAt(0) as Number;
				dialogViewsMaxDurations.removeItemAt(0);
				processNewDialog(dialogViewToShow, maxDuration);
			}
		}
		
		private static function disableMaxDurationTimer():void {
			if (maxDurationTimer != null) {
				maxDurationTimer.stop();
				maxDurationTimer = null;
			}
		}
		
		/**
		 * if maxDurationInSeconds specified then the dialog will be closed after the specified time
		 */
		public static function openSimpleDialog(title:String, message:String, maxDurationInSeconds:Number = Number.NaN):void {
			var alert:DialogView = Dialog.service.create(
				new AlertBuilder()
				.setTitle(title)
				.setMessage(message)
				.addOption("Ok", DialogAction.STYLE_POSITIVE, 0)
				.build()
			);
			DialogService.addDialog(alert, maxDurationInSeconds);
		}
	}
}