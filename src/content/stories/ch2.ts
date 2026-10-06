import type { StoryDef } from "../../core/run/types";
import { bg, bond, choice, join, jinyuan, li, ling, linTiannan, n, reward, story, villager, yue } from "./lines";

/**
 * 第二章：隱龍窟・白河村。
 * 月如入隊追靈兒；蛇妖男死後狐狸精接續；白河村以六神丹救回靈兒。
 * 教學（§5.1）：第一次合擊。
 */
export const CH2_STORIES: StoryDef[] = [
  story("c2_depart", "lin_manor", [
    n("天一亮，逍遙就背起包袱。"),
    linTiannan("你要走？"),
    li("靈兒一個人在外面，我得去找她。"),
    linTiannan("那個……蛇身的姑娘？", "angry"),
    li("她是我的妻子。", "resolve"),
    n("林天南盯著他看了很久，最後嘆了口氣。"),
    yue("爹，我跟他去。", "resolve"),
    linTiannan("月如！", "surprise"),
    yue("他是在我們林家的擂台上贏的，婚約的事還沒說清楚，不能讓他就這麼跑了。"),
    yue("再說……那個靈兒，昨晚是為了護著我們才現了原形的。我林月如不欠人情。"),
    jinyuan("表妹，路上危險……"),
    yue("表哥，你在家讀你的書，乖乖等我回來。", "smile"),
    linTiannan("……罷了。你從小就是這個脾氣。李逍遙，月如若少了一根頭髮，我拿你是問。"),
    join("lin_yueru"),
    yue("喂，姓李的。打架的時候跟緊我，我們兩個輪流出手，一鞭一劍，氣勢會越來越盛。", "smile"),
    li("輪流出手？聽起來像在跳舞。"),
    yue("你再廢話，我先抽你一鞭。", "angry"),
  ]),

  story("c2_road_outro", "suzhou_outskirts", [
    yue("還不錯嘛。剛才那一下，你跟上我的節奏了。"),
    li("你也還行。就是脾氣差了點。", "smile"),
    yue("你說什麼？", "angry"),
    n("路邊的茶棚裡，有人在說隱龍窟的事：最近有條大蛇，夜裡把迷路的姑娘捲進洞去。"),
    li("……大蛇？", "surprise"),
    yue("走！", "resolve"),
  ]),

  story("c2_cave_intro", "yinlong_cave", [
    n("隱龍窟裡又濕又冷，岩壁上的水珠像一隻隻眼睛。"),
    yue("你聞到了嗎？好重的腥味。"),
    li("靈兒……你在裡面嗎？"),
    n("洞穴深處，傳來細細的、像是蛇在吐信的聲音。"),
  ]),

  story("c2_boss_intro", "yinlong_cave_deep", [
    n("洞窟最深處，一個半人半蛇的男人盤在石台上。石台旁，靈兒倒在地上，一動也不動。"),
    li("靈兒！", "surprise"),
    n("蛇妖男吐出長長的信子，眼睛裡閃著綠光。"),
    n("「她身上流著和我一樣的血……她是我的。」"),
    li("她身上流的是她自己的血。她是她自己的！", "angry"),
    yue("跟一條蛇講什麼道理？打就是了！", "resolve"),
  ]),

  story("c2_boss_outro", "yinlong_cave_deep", [
    n("狐狸精化成一縷青煙，散在洞窟裡。"),
    li("靈兒！靈兒，醒醒！", "sad"),
    n("靈兒的身子冷得像冰，氣息細得幾乎摸不到。"),
    yue("她中了妖毒……得快點找大夫。山下有個白河村，我們走！", "resolve"),
    n("逍遙背起靈兒，一步也沒停地衝下山。"),
  ]),

  story("c2_tiger", "baihe_village", [
    villager("村外的林子裡有隻吊睛白額大蟲，已經叼走了好幾頭牛……"),
    yue("老虎？正好，本姑娘手癢。", "smile"),
    li("月如，那是老虎，不是街上的無賴。"),
    yue("所以才好玩啊。", "smile"),
  ]),

  story("c2_baihe", "baihe_village", [
    n("白河村，一條白茫茫的河繞著村子流過。"),
    villager("是你們打死了隱龍窟的妖怪？村裡的人都得救了！"),
    li("大夫！有沒有大夫？她中了妖毒——"),
    villager("妖毒……尋常藥是救不了的。要六神丹。"),
    yue("哪裡有六神丹？要多少錢我都出！"),
    villager("村長家裡供著一顆，是祖上傳下來的。你們救了全村，村長一定肯給。"),
    bg("baihe_house"),
    n("六神丹化在水裡，一點一點餵進靈兒嘴裡。"),
    n("過了整整一夜，靈兒的睫毛動了動。"),
    ling("……逍遙哥哥？", "surprise"),
    li("靈兒！你醒了！", "smile"),
    ling("我……那天晚上，你都看見了吧。我不是人，我是……", "sad"),
    choice(
      ["「你是我的妻子。」", [
        li("你是趙靈兒，是我李逍遙的妻子。別的我都不管。", "resolve"),
        ling("……嗯。", "smile"),
        bond("zhao_linger", 2),
      ]],
      ["「你救過我們，這就夠了。」", [
        li("那天晚上你是為了護著我們才變身的。這樣的人，怎麼會是妖怪？"),
        ling("逍遙哥哥……", "smile"),
        bond("zhao_linger", 1),
      ]],
    ),
    yue("咳。醒了就好。", "smile"),
    ling("你是……林家的姑娘？"),
    yue("林月如。這一路上，算我一份。", "smile"),
    ling("謝謝你，月如姐姐。"),
    yue("……誰、誰是你姐姐。", "surprise"),
    bond("lin_yueru", 1),
    join("zhao_linger"),
    reward({ cards: ["item_herb"] }),
  ]),
];
