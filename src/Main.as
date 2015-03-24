package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.events.Event;

	import starling.core.Starling;

	[SWF(width="550", height="400")]
	public class Main extends Sprite {
		private var starling:Starling;

		public function Main() {
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		private function onAdded(event:Event):void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = 60;

			removeEventListener(Event.ADDED_TO_STAGE, onAdded);

			Starling.handleLostContext = true;

			starling = new Starling(Scene, stage, null, null, "auto", Context3DProfile.BASELINE_CONSTRAINED);

			starling.supportHighResolutions = true;
			starling.start();
			starling.stage.color = 0x444444;
			stage.addEventListener(Event.RESIZE, onResize);
			onResize(null);
		}

		private function onResize(event:Event):void {
			starling.stage.stageWidth = stage.stageWidth;
			starling.stage.stageHeight = stage.stageHeight;
			starling.viewPort.width = stage.stageWidth;
			starling.viewPort.height = stage.stageHeight;
		}
	}
}