extends Node2D

#
  #호출 체인 (잠 → 스폰)
#
  #1. 잠자면 Game1.NewDay → Game1.newDayAfterFade (Game1.cs:7088)
  #foreach (GameLocation location in Game1.locations)
	  #location.DayUpdate(Game1.dayOfMonth);
	 #모든 로케이션이 한꺼번에 갱신됩니다. 플레이어가 어디서 잤는지는 무관.
  #2. Farm.DayUpdate (Locations/Farm.cs:226) → base.DayUpdate 호출 후 농장 전용 스폰 추가
  #3. Forest.DayUpdate (Locations/Forest.cs:234) → base.DayUpdate 만 호출 (숲은 자기 스폰 코드가 없고 봄에 forage crop
	 #심는 것과 행상인 처리뿐)
  #4. 공통 로직은 전부 GameLocation.DayUpdate (Locations/2GameLocation.cs:2768)
#
  #공통: GameLocation.DayUpdate
#
  #terrainFeatures 전부 .dayUpdate()   ← 나무 성장/번식은 여기 (Tree.dayUpdate)
  #objects 전부 .DayUpdate()           ← destroyOvernight 인 것 제거
  #if (isOutdoors && !map.Properties["skipWeedGrowth"]) {
	  #if (dayOfMonth % 7 == 0 && !(this is Farm)) {   // 농장 제외, 주 1회
		  #isSpawnedObject 인 오브젝트 전부 삭제        // 채집물 리셋
		  #numberOfSpawnedObjectsOnMap = 0
		  #spawnObjects(); spawnObjects();
	  #}
	  #spawnObjects();                                  // 매일
	  #if (dayOfMonth == 1) spawnObjects();
	  #if (DaysPlayed < 4) spawnObjects();
#
	  #if (map 에 "Paths" 레이어 있음 && !(this is Farm)) {  // 숲 등 비농장 맵의 나무 재생
		  #Paths 레이어의 모든 타일에 대해 50% 확률로
			#tileIndex 9→참나무(1), 10→단풍(2), 11→소나무(3), 12→머쉬룸(6), 31/32→마호가니/팜(9/8)
			#겨울이면 9,10 은 +3 (겨울 스프라이트 변형)
			#해당 칸에 furniture/terrainFeature/object 가 없으면 new Tree(which, 2)  // 2 = 묘목 단계
	  #}
  #}
  #if (!isFarm) 빈 HoeDirt 삭제   // 비농장 맵의 경작지는 매일 리셋
  #if (!(this is Farm)) HandleGrassGrowth
#
  #숲의 나무 재생 핵심: 숲 맵은 Paths 레이어에 "나무가 있어야 할 자리"를 타일 인덱스로 표시해 두고, 매일 그 자리가 비어
  #있으면 50% 확률로 stage 2 묘목을 다시 심습니다. 즉 나무를 베어도 며칠 뒤 같은 자리에 다시 자랍니다.
#
  #spawnObjects (2GameLocation.cs:10598)
#
  #- Data\Locations 의 계절별 [itemId chance itemId chance ...] 문자열을 읽어 채집물 스폰. Spawnable 백 타일 속성이 있고
	#완전히 빈 칸에만. 맵당 numberOfSpawnedObjectsOnMap < 6 제한.
  #- 끝부분에서 농장/IslandWest 이면 지렁이(590, 아티팩트 스팟) 만 처리하고, 그 외 맵(숲 포함)은 spawnWeedsAndStones() 를
	#호출합니다. 즉 숲의 돌/잡초/나뭇가지 재생은 이 경로입니다.
#
  #spawnWeedsAndStones (2GameLocation.cs:10682) — 돌·잡초·나뭇가지
#
  #개수 = numDebris 지정 없으면: 95% 확률로 (25%: 10~20개 / 75%: 5~10개), 5% 확률 0
  #비 오면 ×2, 매월 1일 ×5
  #농장이 아니면 /2
  #spawnFromOldWeeds=true (기본):
	  #objects 가 하나도 없으면 return       ← "씨앗" 오브젝트가 없으면 번식 안 함
	  #기존 object 를 랜덤으로 하나 뽑고 그 주변 3x3 랜덤 칸을 목표로 함
	  #(농장은 Diggable 칸에만, 비농장은 Diggable 아닌 칸에만) + NoSpawn 없음 + Type != Wood
	  #목표칸이 빈칸이거나, 다른 잡초/돌/가지거나, HoeDirt/Flooring 이면 스폰 허용
	  #부모가 Stone/Twig 이면 50%: 돌(343/450) 또는 가지(294/295)
	  #부모가 Weed 이면: getWeedForSeason
	  #농장 && spawnFromOldWeeds=false 일 때만 5% 확률로 new Tree(1~3 랜덤, stage 0~2)
	  #목표칸에 작물/설치물이 있으면 부숴버리고 "Farm_WeedsDestruction" 메시지 (잡초 침식)
#
  #즉 스타듀의 돌/잡초는 "맵 전체 랜덤 스폰"이 아니라 기존 잔해 옆으로 번지는 셀룰러 방식이고, 다 치우면 더 안 생깁니다.
#
  #농장 전용: Farm.DayUpdate (Farm.cs:440~465)
#
  #가을 && 5% 확률: 다 자란 나무 하나를 treeType 7 (단풍/mushroom tree) 로 변환
  #addCrows()
  #if (!겨울) spawnWeedsAndStones(여름 30 : 20)   ← 농장은 개수 고정, 위 번식 규칙 그대로
  #spawnWeeds(false)                              ← 아래
  #HandleGrassGrowth
#
  #spawnWeeds (2GameLocation.cs:2670) 는 이름과 달리 풀(Grass terrainFeature) 스폰입니다:
  #- 농장 5~11회, 봄 1일은 ×15
  #- 각 시도마다 최대 3번 랜덤 좌표 뽑아서 15% 확률로 which=1(일반 풀) → Diggable + 빈칸 + NoSpawn 아님 이면 new Grass(1,
	#1~2줄기)
  #- 35% 확률로 num5=1 분기를 타는데, 농장에서는 이 경우 25% 확률로 함수 자체를 return 해버림 (풀 스폰 수 억제용)
#
  #나무 자체 번식: Tree.dayUpdate (TerrainFeatures/Tree.cs:374)
#
  #겨울이 아니거나 (특수 수종 / 비료) 일 때만 성장:
	  #stage 4 묘목은 주변 3x3 에 다 자란 나무가 있으면 성장 정지 (간격 유지)
	  #stage 0 씨앗 위에 object 가 있으면 정지
	  #20% 확률로 growthStage++ (비료면 100%, 마호가니는 15%)
  #stage >= 5 && environment is Farm && 15% 확률:
	  #자기 좌표 ±3 랜덤 칸에 같은 treeType 씨앗 (stage 0) 심음   ← 농장에서만 자연 번식
  #stage >= 5 && 5% 확률: hasSeed = true (흔들면 씨앗 드롭)
#
  #정리: 우리 게임에 옮길 때 핵심만
#
  #┌──────────────┬──────────────────────────────────────────────────────┬───────────────────────────────────────────┐
  #│     대상     │                         농장                         │                    숲                     │
  #├──────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────┤
  #│ 나무         │ 다 자란 나무가 15%로 ±3칸에 씨앗 살포 +              │ Paths 레이어에 적힌 고정 좌표에 50%로     │
  #│              │ spawnWeedsAndStones 5% 랜덤 묘목                     │ stage 2 묘목 재심기                       │
  #├──────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────┤
  #│ 돌/가지/잡초 │ 기존 잔해 옆 3x3 로 번식, 여름 30 / 그 외 20개, 겨울 │ 같은 함수, 개수 랜덤 후 /2, Diggable 아닌 │
  #│              │  0                                                   │  칸만                                     │
  #├──────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────┤
  #│ 풀           │ spawnWeeds 로 랜덤 좌표에 Grass 5~11회               │ 안 함                                     │
  #├──────────────┼──────────────────────────────────────────────────────┼───────────────────────────────────────────┤
  #│ 채집물       │ 안 함                                                │ Data\Locations 테이블, 주 1회 전부 리셋,  │
  #│              │                                                      │ 맵당 최대 6개                             │
  #└──────────────┴──────────────────────────────────────────────────────┴───────────────────────────────────────────┘
#
  #세 가지 설계 포인트가 눈에 띕니다: (1) 잔해는 랜덤 스폰이 아니라 인접 번식이라 완전히 청소하면 멈춤, (2) 숲 나무는 맵
  #데이터(Paths 레이어)가 자리를 지정해서 항상 같은 자리에 재생, (3) 모든 로케이션이 잠잘 때 한꺼번에 돌아가고 플레이어
  #위치와 무관.
#
  #클론한 소스는 scratchpad/sdv 에 있으니 더 볼 파일이 있으면 말씀해 주세요.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
