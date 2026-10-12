extends Node

## TODO: 저장해야하는 데이터
# 플레이어, 인벤, 퀘스트 관련 등

# 이걸 진짜 저장해야 하는가?
var current_scene: DataTypes.Levels

# character_customization > skip안하면 tutorial로 
# 이걸 기반으로 ui 표시 안함. 시간 표시 안함.
var did_skip_tutorial: bool = false
