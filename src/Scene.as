package {

	import starling.extensions.sap.ParticleSystem;
	import starling.extensions.sap.ParticleTextureAtlas;

	import flash.geom.Vector3D;

	import starling.display.Sprite;
	import starling.textures.Texture;

	public class Scene extends Sprite {
		[Embed("assets/fire_diffuse.jpg")]
		static private const EmbedFireDiffuse:Class;
		[Embed("assets/fire_opacity.atf", mimeType="application/octet-stream")]
		static private const EmbedFireOpacity:Class;
		private var particleSystem:ParticleSystem = new ParticleSystem();

		public function Scene() {

			var fireDiffuse:Texture = Texture.fromEmbeddedAsset(EmbedFireDiffuse);
			var fireOpacity:Texture = Texture.fromEmbeddedAsset(EmbedFireOpacity);

			var fireSmokeAtlas:ParticleTextureAtlas = new ParticleTextureAtlas(fireDiffuse, fireOpacity, 8, 8, 0, 16, 30, true);
			var fireFireAtlas:ParticleTextureAtlas = new ParticleTextureAtlas(fireDiffuse, fireOpacity, 8, 8, 16, 16, 30, true);
			var fireFlameAtlas:ParticleTextureAtlas = new ParticleTextureAtlas(fireDiffuse, fireOpacity, 8, 8, 32, 32, 45, true, 0.5, 0.5);

			var fire:FireTest = new FireTest(fireSmokeAtlas, fireFireAtlas, fireFlameAtlas, 100, false);
			particleSystem.gravity = new Vector3D(0, -1, 0);
			particleSystem.wind = new Vector3D(1, 10, 0);
			addChild(particleSystem);
			particleSystem.addEffect(fire);
			particleSystem.play();

			particleSystem.x = 125;
			particleSystem.y = 170;
		}
	}
}
