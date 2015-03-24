package {

	import com.starling.effects.ParticleEffect;
	import com.starling.effects.ParticlePrototype;
	import com.starling.effects.ParticleTextureAtlas;

	import flash.display3D.Context3DBlendFactor;
	import flash.geom.Vector3D;
	import flash.utils.setTimeout;

	public class FireTest extends ParticleEffect {

		static private var smokePrototype:ParticlePrototype;
		static private var firePrototype:ParticlePrototype;
		static private var flamePrototype:ParticlePrototype;

		static private var liftSpeed:Number = 60;
		static private var windSpeed:Number = 10;

		static private var pos:Vector3D = new Vector3D();

		public function FireTest(smoke:ParticleTextureAtlas, fire:ParticleTextureAtlas, flame:ParticleTextureAtlas, live:Number = 1, repeat:Boolean = false) {

			var ft:Number = 1 / 30;

			if (smokePrototype == null) {
				smokePrototype = new ParticlePrototype(128, 128, smoke, false, Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
				smokePrototype.addKey(0 * ft, 0, 0.40, 0.40, 0.65, 0.25, 0.00, 0.00);
				smokePrototype.addKey(9 * ft, 0, 0.58, 0.58, 0.65, 0.45, 0.23, 0.30);
				smokePrototype.addKey(19 * ft, 0, 0.78, 0.78, 0.65, 0.55, 0.50, 0.66);
				smokePrototype.addKey(40 * ft, 0, 1.21, 1.21, 0.40, 0.40, 0.40, 0.27);
				smokePrototype.addKey(54 * ft, 0, 1.50, 1.50, 0.00, 0.00, 0.00, 0.00);
			}
			if (firePrototype == null) {
				firePrototype = new ParticlePrototype(128, 128, fire, false, Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
				firePrototype.addKey(0 * ft, 1, 0.30, 0.30, 1.00, 1.00, 1.00, 0.00);
				firePrototype.addKey(8 * ft, 2, 0.40, 0.40, 1.00, 1.00, 1.00, 0.85);
				firePrototype.addKey(17 * ft, 3, 0.51, 0.51, 1.00, 0.56, 0.48, 0.10);
				firePrototype.addKey(24 * ft, 4, 0.60, 0.60, 1.00, 0.56, 0.48, 0.00);
			}
			if (flamePrototype == null) {
				flamePrototype = new ParticlePrototype(128, 128, flame, true, Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE);
				flamePrototype.addKey(0 * ft, 0, 1.00, 1.00, 1.00, 1.00, 1.00, 0.00);
				flamePrototype.addKey(10 * ft, 0, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00);
				flamePrototype.addKey(live - 10 * ft, 0, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00);
				flamePrototype.addKey(live, 0, 1.00, 1.00, 1.00, 1.00, 1.00, 0.00);

			}

			addKey(0, keyFrame1);

			var i:int = 0;
			while (true) {
				var keyTime:Number = ft + i * 3 * ft;
				if (keyTime < live) {
					addKey(keyTime, keyFrame);
				} else break;
				i++;
			}

			if (repeat) {
				setTimeout(function ():void {
					var newFire:FireTest = new FireTest(smoke, fire, flame, live, repeat);
					newFire.name = name;
					newFire.scale = scale;
					newFire.position = position;
					newFire.direction = direction;
					particleSystem.addEffect(newFire);
				}, (live - 5 * ft) * 1000);
			}

			setLife(timeKeys[keysCount - 1] + smokePrototype.lifeTime);
		}

		private function keyFrame1(keyTime:Number, time:Number):void {
			var area:Number = 10;
			pos.x = 20;
			pos.y = -random() * area * 0.5;
			var scale:Number = 0.6;
			flamePrototype.createParticle(this, time, pos, 0, scale, scale, 1, 0);
			pos.y += 20;
			flamePrototype.createParticle(this, time, pos, 0, scale, scale, 1, 0.5 * flamePrototype.atlas.rangeLength);
		}

		private function keyFrame(keyTime:Number, time:Number):void {
			var ft:Number = 1 / 30;
			var area:Number = 10;
			for (var i:int = 0; i < 1; i++) {
				pos.x = 20;
				pos.y = -10 - random() * area * 0.5;
				displacePosition(time, 0.7 + random() * 0.5, pos);
				smokePrototype.createParticle(this, time, pos, random() - 0.5, 1.00, 1.00, 1, random() * smokePrototype.atlas.rangeLength);
				pos.y += 20;
				firePrototype.createParticle(this, time, pos, random() - 0.5, 1, 1, 1, random() * firePrototype.atlas.rangeLength);
				firePrototype.createParticle(this, time, pos, random() - 0.5, 1.00, 1.00, 0.70, random() * firePrototype.atlas.rangeLength);
			}
		}

		private function displacePosition(time:Number, factor:Number, result:Vector3D):void {
			result.y -= time * windSpeed * particleSystem.wind.y + time * liftSpeed * factor;
		}

	}
}
