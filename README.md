# l4d2_plugins_coop
+ **求生之路2的一些小插件**
+ 一部分参考各路大佬写（抄）出来的插件，一部分是直接拿的大佬的插件，仅做整理。
+ 如果有适合你的，可以随意下载使用

|                           插件名字                           | 功能介绍                                                     |
| :----------------------------------------------------------: | :----------------------------------------------------------- |
|              [**alone**](./scripting/alone.sp)               | 被特感控制后，扣除血量解控                                   |
|            [**anti_ff**](./scripting/anti_ff.sp)             | 友伤达到一定值惩罚攻击者                                     |
|    [**eq_finale_tanks**](./scripting/eq_finale_tanks.sp)     | 救援减少一次事件，不再需要文件，自动写入最后一关             |
|      [**give_pill_kit**](./scripting/give_pill_kit.sp)       | 开局离开安全屋发药包                                         |
|            [**hextags**](./scripting/hextags.sp)             | 游戏内聊天框称号插件，联动时长获取插件: [l4d2_player_time](./other_version/l4d2_player_time.sp)<br/>**注意：需要config文件**<br/>**include文件需要：**[[**chat-processor.inc**](./scripting/include/chat-processor.inc)] [[**hexstocks.inc**](./scripting/include/hexstocks.inc)] [[**hextags.inc**](./scripting/include/hextags.inc)] |
|  [**hitsound_branches**](./scripting/hitsound_branches.sp)   | 击中反馈三合一版本，vpk扩展音效材质 [击杀及击中反馈](./[材质]击杀及击中反馈.vpk) |
|           [**hostname**](./scripting/hostname.sp)            | 根据端口号改服名，显示部分突变模式(不常用的模式没写，仅写了部分战役和生还者)和难度 <br/>**注意：需要data文件** |
|  [**infected_teleport**](./scripting/infected_teleport.sp)   | 基于 [infected_teleport](https://github.com/GlowingTree880/L4D2_LittlePlugins/tree/main/InfectedTeleport) 删除logger依赖 |
|       [**join_out_msg**](./scripting/join_out_msg.sp)        | 加入退出服务器提示信息                                       |
|           [**kicktank**](./scripting/kicktank.sp)            | 使用指令后单次关卡只会出现一个克                             |
|         [**killregain**](./scripting/killregain.sp)          | 击杀特感小僵尸回血回子弹，修复倒地bug，增加击杀女巫回血      |
|  [**l4d2_auto_medical**](./scripting/l4d2_auto_medical.sp)   | 根据人数自动倍数医疗物品                                     |
|      [**l4d2_doorlock**](./scripting/l4d2_doorlock.sp)       | 所有人加载完毕才能打开安全门，基于 [**l4d2_doorlock**](https://github.com/umlka/l4d2/tree/main/l4d2_doorlock) 修改，删除翻译文件，增加开关门提示 |
| [**l4d2_friendly_fire**](./scripting/l4d2_friendly_fire.sp)  | 开关队友伤害，!setff on打开友伤，!setff off关闭友伤，!setff normal设置普通友伤，!setff top设置最高友伤（1.0） |
|          [**l4d2_gift**](./scripting/l4d2_gift.sp)           | 掉落礼物盒子并获取奖励 <br/>**注意：需要data和gamedata文件** |
|     [**l4d2_item_hint**](./scripting/l4d2_item_hint.sp)      | 标记物品，仅汉化 <br/>**注意：需要gamedata文件和翻译文件**   |
| [**l4d2_more_medicals**](./scripting/l4d2_more_medicals.sp)  | 手动加载多倍医疗，不随人数动态变化，配合投票插件使用（!mmk 2就是2倍医疗包，!mmp 2就是2倍针药） |
| [**l4d2_player_respawn**](./scripting/l4d2_player_respawn.sp) | 玩家死亡后复活，可以设置复活次数和时间，每次复活后增加时间   |
| [**l4d2_player_status**](./scripting/l4d2_player_status.sp)  | 基于豆瓣酱提示插件修改，删除witchid，增加colors，调整部分提示，增加自杀指令 |
|   [**l4d2_player_time**](./scripting/l4d2_player_time.sp)    | 玩家时长检测，展示总时长，真实时长，最近两周。个人资料关闭公开的玩家无法读取(需要依赖[ripext](https://github.com/ErikMinekus/sm-ripext))<br/>[称号插件依赖版本]：[l4d2_player_time](./other_version/l4d2_player_time.sp) |
| [**l4d2_restore_health**](./scripting/l4d2_restore_health.sp) | 过关回满血，增加一个cvar判定，默认0关闭回血，1为开启回血     |
|      [**l4d2_rpg_tank**](./scripting/l4d2_rpg_tank.sp)       | 给输入!rpg的生还传送回起点安全屋并生成5个克，更改死门模式，召唤尸潮，并于60秒后处死全员 |
|     [**l4d2_satellite**](./scripting/l4d2_satellite.sp)      | 使用马格南射出两种模式的卫星炮                               |
|       [**l4d2_tank_hp**](./scripting/l4d2_tank_hp.sp)        | 根据豆瓣酱坦克提示插件修改，配色更符合下面的坦克击杀数据统计，删除随机女巫血量变成固定血量，坦克血量随难度提升降低，平衡各个难度，新增witch惊扰提示 |
| [**l4d2_tank_random_name**](./scripting/l4d2_tank_random_name.sp) | 修改AI坦克名字为碧蓝档案角色名字                             |
|     [**l4d2_text_info**](./scripting/l4d2_text_info.sp)      | 信息提示，不适用其他服务器                                   |
|  [**l4d_blackandwhite**](./scripting/l4d_blackandwhite.sp)   | 汉化并增加聊天框提示颜色，增加黑白移除提示                   |
| [**l4d_explosion_announcer**](./scripting/l4d_explosion_announcer.sp) | 爆炸提示，修改提示颜色                                       |
| [**l4d_kickloadstuckers**](./scripting/l4d_kickloadstuckers.sp) | 踢出卡在连接状态太久的玩家，仅汉化                           |
| [**l4d_tank_damage_announce**](./scripting/l4d_tank_damage_announce.sp) | [tank_damage2.0.sp](https://github.com/GlowingTree880/L4D2_LittlePlugins/blob/main/TankDamageAnnounce/tank_damage2.0.sp) 基于该插件修改，删除treeutil和logger依赖，删除坦克出现提示，交给其他插件处理 |
| [**l4d_throwable_announcer**](./scripting/l4d_throwable_announcer.sp) | 投掷物提示，修改提示颜色                                     |
|        [**lerpmonitor**](./scripting/lerpmonitor.sp)         | 玩家lerp显示                                                 |
|           [**lockdoor**](./scripting/lockdoor.sp)            | 锁定终点安全门，需要足够人数在范围内才能打开                 |
|         [**match_vote**](./scripting/match_vote.sp)          | 基于 [match_vote](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/match_vote) 修改而成 <br/>增加模式锁定，切换模式必须!rmatch卸载当前模式加载的cfg <br/>同级目录下，文件增加off为卸载文件(例：加载模式文件为coop.cfg，卸载文件就叫coopoff.cfg) <br/>**注意：需要data文件** |
|              [**music**](./scripting/music.sp)               | 在安全屋可以点歌放给所有人，插件没有实现fastdl，使用vpk扩展 [音乐扩展包](./[材质]音乐扩展包.vpk) <br/>**注意：需要data文件** |
|             [**notify**](./scripting/notify.sp)              | 加入退出提示，出安全屋音效，服务器游玩时长提示<br/>[无商店依赖版本]：[notify](./other_version/notify.sp) |
|         [**ping_check**](./scripting/ping_check.sp)          | 进入服务器90秒后检测ping值，超过250ms5次踢出服务器           |
|             [**remove**](./scripting/remove.sp)              | 删除地图所有医疗物资，出门发止痛药，增加通关清除武器         |
|             [**rygive**](./scripting/rygive.sp)              | 基于原插件删除部分功能，增加使用指令会有聊天框提示 <br/>**注意：需要gamedata文件** |
|             [**server**](./scripting/server.sp)              | 服务器部分功能的实现  <br/>重启地图  <br/>安全屋无敌  <br/>关闭闲置提示  <br/>ConVar提示仅管理员可见  <br/>1.1.1 频繁改名踢出  <br/>1.1.2 全球排名和人数  <br/>1.1.3 新增debug模式，来自sorallll的rygive插件  <br/>1.1.4 增加服务器匹配禁用<br/>1.1.7 增加sm提示仅管理员可见开关<br/>1.1.8 增加ping过高踢出，仅在进入一分钟后检测一次<br/>1.2.0 移除自杀指令，放在其他插件<br/>1.2.5 移除ping检测，更换为[ping_check](./scripting/ping_check.sp)独立插件<br/>1.2.7 增加玩家闲置后一段时间移动到旁观位置 |
|         [**server_hud**](./scripting/server_hud.sp)          | 融合sorallll和豆瓣酱的hud，提供几种风格<br/>1. 坦克女巫路程居左，北京时间、团灭次数、地图关卡、人数居右<br/>2. 坦克女巫路程居左，服名、人数居右 <br/>3. 北京时间、团灭次数、地图关卡、人数、击杀数量居右 |
|        [**server_name**](./scripting/server_name.sp)         | 基于Anne的服名插件修改，用于zonemod药抗 <br/>**注意：需要data文件** |
|               [**shop**](./scripting/shop.sp)                | 采用sqlite数据库保存数据，功能和shop_lite一样<br/>详细更新说明在源码里<br/>安装过插件的，建议删除data/sqlite文件夹下的数据库文件，再更新插件重建数据库表<br/>[无个人信息统计版本]：[shop_b](./other_version/shop_b.sp)<br/>[使用colors依赖版本]：[shop_c](./other_version/shop_c.sp) |
|          [**shop_lite**](./scripting/shop_lite.sp)           | 商店插件说明:  <br/>每关提供几次机会白嫖部分武器，cvar可自行设定每关几次  <br/>!buy !gw打开商店面板  <br/>!chr快速选铁喷，!pum快速选木喷，!uzi快速选uzi，!smg快速选smg  <br/>!ammo补充后备弹夹，cvar设置多长时间补充一次  <br/>增加出门近战发放，读取steamid写入data/melee.txt文件，再次进服自动加载之前选择  <br/>增加一个cvar控制开关商店  <br/>2.0新增管理员指令开关商店，!shop off关闭商店，!shop on打开商店，!shop查看当前商店开关情况  <br/>2.1新增白嫖近战菜单 |
|         [**slots_vote**](./scripting/slots_vote.sp)          | 投票增加最大人数，管理直接修改，玩家投票修改                 |
|       [**survivor_mvp**](./scripting/survivor_mvp.sp)        | 基于 [survivor_mvp](https://github.com/GlowingTree880/L4D2_LittlePlugins/tree/main/SurvivorMVP) 修改，删除部分依赖，修改配色，细化rank排名，增加cvar控制 |
|                [**svs**](./scripting/svs.sp)                 | 固定回合模式的生还者对抗生还者（模式详细介绍请看源码）       |
|               [**svs2**](./scripting/svs2.sp)                | 随机复活模式的生还者对抗生还者（模式详细内容请看源码）       |
|           [**taketank**](./scripting/taketank.sp)            | 战役模式输入!pb加入接管坦克候选池，随机抽取一个玩家接管坦克，管理员输入!tt接管AI坦克 |
|            [**tankhud**](./scripting/tankhud.sp)             | 不限制模式显示坦克状态，仅限旁观和特感，删除部分依赖，使插件通用在服务器 |
|            [**tankrun**](./scripting/tankrun.sp)             | 修改坦克同屏数量和产生时间，增加狙击类武器救倒地玩家，可开启玩家游玩坦克<br/>请修改突变模式为tank run再加载插件，否则出现bug并不在修复内容 |
|               [**vote**](./scripting/vote.sp)                | Anne的投票加载cfg和指令，删除数据库相关功能，仅保留投票和踢人，增加root权限管理防踢 |
| [**witch_damage_announce**](./scripting/witch_damage_announce.sp) | zonemod的witch伤害提示，和上面tank提示一起使用，配色统一 <br/>**注意：需要翻译文件** |



