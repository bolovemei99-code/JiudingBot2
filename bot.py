import logging
import sqlite3
from datetime import datetime
import random
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ApplicationBuilder, CommandHandler, CallbackQueryHandler, ContextTypes
import os

# 配置日志
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# 环境变量
TOKEN = os.getenv("BOT_TOKEN", "8231003819:AAEt5YEkLzW9575IYul0f-oXW_ZCYAlNExM")
PLATFORM_URL = os.getenv("PLATFORM_URL", "https://jdyl.me/?ref=tg")

# 初始化数据库
def init_db():
    conn = sqlite3.connect("users.db")
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (user_id INTEGER PRIMARY KEY, messages INTEGER, last_active TEXT, vip_status INTEGER)''')
    conn.commit()
    conn.close()

# 欢迎消息
WELCOME_TEXT = f"""🔥欢迎加入【九鼎娱乐东南亚福利群】！
🎰电子福利：注册送$10体验金，玩PG老虎机爆大奖！{PLATFORM_URL}
🐟捕鱼技巧：每日高爆率分享，金币赠送！
⚽体育信号：泰超/英超预测，胜率65%+！
🎁入群抽$20 USDT！规则：禁广告/私聊，18+理性娱乐。问题@admin。
Bot命令：/tips 获取信号，/subscribe 订阅VIP"""

# 示例信号
TIPS_EXAMPLES = [
    "📊泰超：曼谷联胜 @1.85",
    "🐟捕鱼技巧：火箭炮瞄鲨鱼群，高爆率5000倍！",
    "🎰PG《Fortune Tiger》免费10转，注册领！"
]

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    init_db()
    conn = sqlite3.connect("users.db")
    c = conn.cursor()
    c.execute("INSERT OR IGNORE INTO users (user_id, messages, last_active, vip_status) VALUES (?, ?, ?, ?)",
              (user_id, 0, datetime.now().isoformat(), 0))
    conn.commit()
    conn.close()
    
    keyboard = [[InlineKeyboardButton("🎰 访问平台", url=PLATFORM_URL)]]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(WELCOME_TEXT, reply_markup=reply_markup)

async def tips(update: Update, context: ContextTypes.DEFAULT_TYPE):
    tip = random.choice(TIPS_EXAMPLES)
    await update.message.reply_text(f"今日推荐：\n{tip}")

async def subscribe(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("VIP订阅功能开发中，敬请期待！")

def main():
    logger.info("Starting bot...")
    init_db()
    
    app = ApplicationBuilder().token(TOKEN).build()
    
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("tips", tips))
    app.add_handler(CommandHandler("subscribe", subscribe))
    
    logger.info("Bot started successfully!")
    app.run_polling()

if __name__ == "__main__":
    main()
