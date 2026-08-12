extends Node2D

@onready var game_tile_map: TileMapLayer = $GameTileMap/Floors


@export var noise_height_text: NoiseTexture2D
@export var noise_tree_text: NoiseTexture2D

var noise: Noise
var tree_noise: Noise

var land_source_id = 0
var water_source_id = 2
var water_atlas = Vector2i(0, 0)
var land_atlas = Vector2i(5, 0)

var proc_terrains_set_id = 1
var sand_tiles_arr = []
var terrain_sand_int = 0

var grass_tiles_arr = []
var terrain_grass_int = 1

var cliff_tiles_arr = []
var terrain_cliff_int = 2

@export var tree_scene: PackedScene = preload("res://scenes/objects/trees/SmallTree.tscn")
var tree_tiles_arr = []


var width: int = 100
var height: int = 100

var noise_val_arr = []

func _ready():
	noise = noise_height_text.noise
	tree_noise = noise_tree_text.noise
	generate_world()
	_add_debug_zoom_buttons()

func _add_debug_zoom_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugZoomButtons"
	layer.layer = 128  
	add_child(layer)

	var box := HBoxContainer.new()
	box.position = Vector2(8, 8)
	box.add_theme_constant_override("separation", 4)
	layer.add_child(box)

	for factor in [1.0, 3.0, 5.0]:
		var b := Button.new()
		b.text = "%dx" % factor
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_set_debug_zoom.bind(factor))
		box.add_child(b)

func _set_debug_zoom(factor: float) -> void:
	var cam := get_node_or_null("Player/Camera2D") as Camera2D
	if cam == null:
		return
	cam.zoom = Vector2.ONE / factor

func generate_world():
	for x in range(-width/2, width/2):
		for y in range(-height/2, height/2):
			var noise_val = noise.get_noise_2d(x, y)
			var tree_noise_val = tree_noise.get_noise_2d(x, y)

			noise_val_arr.append(noise_val)

			# placing ground
			if noise_val > 0.0:
				if noise_val > 0.2:
					if noise_val > 0.6:
						cliff_tiles_arr.append(Vector2i(x,y))
					grass_tiles_arr.append(Vector2i(x,y))
				sand_tiles_arr.append(Vector2i(x,y))

				# placing trees
				if noise_val > 0.05 and noise_val < 0.17 and tree_noise_val > 0.17:
					tree_tiles_arr.append(Vector2i(x,y))
				pass


			elif noise_val < 0.0:
				game_tile_map.set_cell(Vector2i(x,y), water_source_id, water_atlas)
				pass
	game_tile_map.set_cells_terrain_connect(sand_tiles_arr, proc_terrains_set_id, terrain_sand_int)
	game_tile_map.set_cells_terrain_connect(grass_tiles_arr, proc_terrains_set_id, terrain_grass_int)
	game_tile_map.set_cells_terrain_connect(cliff_tiles_arr, proc_terrains_set_id, terrain_cliff_int)

	place_trees()

	print("highest", noise_val_arr.max())
	print("lowest", noise_val_arr.min())
	print("sand=%d  grass=%d  cliff=%d  tree=%d" % [sand_tiles_arr.size(), grass_tiles_arr.size(), cliff_tiles_arr.size(), tree_tiles_arr.size()])

func place_trees():
	if tree_scene == null:
		return

	# 나무끼리, 그리고 플레이어와 앞뒤가 맞도록 y_sort 컨테이너에 담는다.
	var container = Node2D.new()
	container.name = "Trees"
	container.y_sort_enabled = true
	add_child(container)

	for coords in tree_tiles_arr:
		var tree = tree_scene.instantiate()
		tree.position = game_tile_map.map_to_local(coords)
		container.add_child(tree)

#
#● 핵심 함수는 GameLocation.spawnWeedsAndStones() 입니다. 저장소가 partial class를 파일별로 쪼개놔서
  #Locations/2GameLocation.cs에 들어있어요.
#
  #호출 경로
#
  #자고 일어나면 → 모든 로케이션의 DayUpdate(dayOfMonth) 호출 → Farm.DayUpdate가 오버라이드
#
  #Locations/Farm.cs:460-464 (https://github.com/WeDias/StardewValley/blob/main/Locations/Farm.cs#L460)
  #this.addCrows();
  #if (!Game1.currentSeason.Equals("winter"))
	#this.spawnWeedsAndStones(Game1.currentSeason.Equals("summer") ? 30 : 20);
  #this.spawnWeeds(false);          // 이건 잔디(Grass) 전용
  #this.HandleGrassGrowth(dayOfMonth);
#
  #밤사이 생성기는 사실 3종류로 분리돼 있습니다:
#
  #┌────────────────────┬───────────────────────────────────────────────────────────────────────────┬───────────────┐
  #│        함수        │                                   위치                                    │     담당      │
  #├────────────────────┼───────────────────────────────────────────────────────────────────────────┼───────────────┤
  #│                    │                                                                           │ 채집물(forage │
  #│ spawnObjects()     │ 2GameLocation.cs:10598 (https://github.com/WeDias/StardewValley/blob/main │ ) — Data\Loca │
  #│                    │ /Locations/2GameLocation.cs#L10598)                                       │ tions 테이블  │
  #│                    │                                                                           │ 기반          │
  #├────────────────────┼───────────────────────────────────────────────────────────────────────────┼───────────────┤
  #│ spawnWeedsAndStone │ 2GameLocation.cs:10682 (https://github.com/WeDias/StardewValley/blob/main │ 돌·나뭇가지·  │
  #│ s()                │ /Locations/2GameLocation.cs#L10682)                                       │ 잡초 ←        │
  #│                    │                                                                           │ 질문하신 것   │
  #├────────────────────┼───────────────────────────────────────────────────────────────────────────┼───────────────┤
  #│ spawnWeeds()       │ 2GameLocation.cs:2670 (https://github.com/WeDias/StardewValley/blob/main/ │ 잔디 Grass    │
  #│                    │ Locations/2GameLocation.cs#L2670)                                         │ 터레인        │
  #└────────────────────┴───────────────────────────────────────────────────────────────────────────┴───────────────┘
#
  #spawnWeedsAndStones 구조
#
  #1) 조기 탈출 (10684-10694)
  #if (this is Farm && Game1.getFarm().isBuildingConstructed("Gold Clock")) return;
  #if (this is Beach || GetSeasonForLocation() == "winter" || this is Desert) return;
  #골드 시계가 여기서 막습니다. 겨울엔 아예 안 생김.
#
  #2) 개수 결정 (10695-10703)
  #int n = numDebris != -1 ? numDebris
		#: (random < 0.95 ? (random < 0.25 ? Next(10,21) : Next(5,11)) : 0);
  #if (비)          n *= 2;
  #if (dayOfMonth==1) n *= 5;   // 매달 1일 폭증
  #if (!(this is Farm)) n /= 2;
#
  #3) 위치 선정 — 여기가 핵심 아이디어 (10706-10714)
#
  #spawnFromOldWeeds 기본값이 true라서, 맵 전체 랜덤이 아니라 "기존 오브젝트 옆"에 붙어서 자랍니다.
  #Vector2 offset = spawnFromOldWeeds
	#? new Vector2(random.Next(-1,2), random.Next(-1,2))   // 8방향 이웃
	#: new Vector2(random.Next(mapW), random.Next(mapH));  // 완전 랜덤
#
  #if (spawnFromOldWeeds)
	#parent = this.objects.Pairs.ElementAt(random.Next(objects.Count()));  // 부모를 하나 뽑음
  #Vector2 target = offset + parent.Key;
  #즉 셀룰러 확산(감염) 모델입니다. 잡초를 안 치우면 그 주변으로 계속 번져서 눈덩이처럼 불어나고, 싹 밀어놓으면 증식원이
  #없어서 훨씬 덜 생겨요. (objects.Count() <= 0 && spawnFromOldWeeds면 그냥 return — 10700)
#
  #완전 랜덤(spawnFromOldWeeds: false)은 새 게임 맵 초기화 때만 씁니다 (956-962
  #(https://github.com/WeDias/StardewValley/blob/main/Locations/2GameLocation.cs#L956)).
#
  #4) 타일 유효성 검사 (10728-10760)
  #int want = (this is Farm) ? 1 : 0;                          // 농장은 Diggable 타일에만
  #int has  = doesTileHaveProperty(x,y,"Diggable","Back") != null ? 1 : 0;
  #if (want == has && NoSpawn 없음 && Type != "Wood") { ... }
  #- 농장은 Diggable(경작 가능) 타일에만, 반대로 광산 입구 같은 바깥 지역은 Diggable이 아닌 타일에만 생성 (want == has로
  #XNOR 체크하는 게 재밌는 트릭)
  #- 완전히 빈 타일이거나, HoeDirt(갈아놓은 땅)/Flooring(바닥재) 위면 통과
#
  #5) 종류 결정 — "유전" (10770-10778)
  #if (random < 0.5 && !weedsOnly &&
	  #(!spawnFromOldWeeds || parent.Name == "Stone" || parent.Name.Contains("Twig")))
	  #id = random >= 0.5 ? (random < 0.5 ? 343 : 450)   // 나뭇가지
						 #: (random < 0.5 ? 294 : 295);  // 돌
  #else if (!spawnFromOldWeeds || parent.Name.Contains("Weed"))
	  #id = getWeedForSeason(random, season);            // 계절별 잡초 스프라이트
#
  #if (this is Farm && !spawnFromOldWeeds && random < 0.05)
	  #terrainFeatures.Add(pos, new Tree(random.Next(3)+1, random.Next(3)));  // 나무 묘목
  #부모의 종류가 자식에게 유전됩니다. 돌 옆엔 돌/나뭇가지, 잡초 옆엔 잡초. 그래서 게임 하다 보면 돌이 무더기로 뭉쳐 있는
  #지형이 생겨요.
#
  #6) 기존 물건 파괴 (10783-10815)
  #if (objects.ContainsKey(target)) {
	#if (obj is Fence || obj is Chest) continue;         // 울타리·상자는 안전
	#if (이름 있는 오브젝트) { destroyed = true; }         // 나머지는 파괴
	#objects.Remove(target);
  #}
  #if (terrainFeatures[target] is HoeDirt or Flooring) terrainFeatures.Remove(target);  // 밭·바닥재 삭제
#
  #if (destroyed && this is Farm && DaysPlayed > 1)
	#broadcastGlobalMessage("Strings\\Locations:Farm_WeedsDestruction");  // "밤사이 잡초가..."
#
  #참고: spawnObjects의 시드 처리
#
  #채집물 쪽은 결정론적 시드를 씁니다 (10600) — 멀티플레이 동기화용:
  #Random random = new Random((int)Game1.uniqueIDForThisGame / 2 + (int)Game1.stats.DaysPlayed);
  #반면 spawnWeedsAndStones는 공유 Game1.random을 그대로 씁니다 (호스트만 계산해서 네트워크로 뿌리는 구조라 상관없음).
