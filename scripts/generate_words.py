from openai import OpenAI
import json
import os
import time

# API 설정 (타임아웃 120초)
client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),  # Set OPENAI_API_KEY environment variable
    timeout=120.0
)

OUTPUT_DIR = r"c:\Users\user\Desktop\spanishstep\assets\data"

LEVELS = {
    "A1": {"start": 1, "count": 600},
    "A2": {"start": 601, "count": 600},
    "B1": {"start": 1201, "count": 1300},
    "B2": {"start": 2501, "count": 2500}
}

CATEGORIES = {
    "A1": ["greetings introductions", "numbers counting", "days months time", "family relationships", 
           "colors sizes", "foods drinks", "basic verbs", "school objects", "body parts", 
           "clothes", "animals", "basic adjectives"],
    "A2": ["household furniture", "health illness", "weather seasons", "transportation", 
           "shopping money", "hobbies sports", "jobs professions", "city places", 
           "past tense verbs", "future expressions", "emotions feelings", "nature outdoors"],
    "B1": ["work career", "education university", "technology internet", "media news", 
           "environment ecology", "social issues", "travel tourism", "housing real estate", 
           "banking finance", "health medical", "culture traditions", "relationships", "abstract concepts"],
    "B2": ["business economics", "politics government", "legal justice", "science research", 
           "arts literature", "psychology behavior", "philosophy ethics", "history civilization", 
           "connectors transitions", "formal expressions", "idioms phrases", "academic vocabulary", "professional terms"]
}

PROMPT = """Generate {count} Spanish words for DELE {level}. Topic: {category}. Start ID: {start_id}.

JSON array only:
[{{"word":"hola","partOfSpeech":"interjection","definition":"hello","example":"Hola, ¿cómo estás?","translations":{{"ko":{{"definition":"안녕","example":"안녕, 어떠세요?"}},"ja":{{"definition":"こんにちは","example":"こんにちは、元気?"}},"zh":{{"definition":"你好","example":"你好，你好吗?"}},"pt":{{"definition":"olá","example":"Olá, como está?"}},"fr":{{"definition":"bonjour","example":"Bonjour, ça va?"}}}},"id":{start_id},"level":"{level}"}}]

Rules: Sequential IDs from {start_id}. Short examples (5-7 words). No duplicates. JSON only."""

def generate_words(level, category, count, start_id):
    for attempt in range(3):
        try:
            print(f"  Attempt {attempt+1}...", end=" ", flush=True)
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "Spanish vocabulary expert. Return valid JSON array only."},
                    {"role": "user", "content": PROMPT.format(count=count, level=level, category=category, start_id=start_id)}
                ],
                temperature=0.7,
                max_tokens=6000
            )
            
            content = response.choices[0].message.content.strip()
            if "```" in content:
                content = content.split("```")[1].replace("json", "", 1).strip()
            
            words = json.loads(content)
            print(f"OK ({len(words)} words)")
            return words
        except Exception as e:
            print(f"Error: {str(e)[:50]}")
            time.sleep(3)
    return []

def save_words(words, level, part_num):
    filepath = os.path.join(OUTPUT_DIR, f"{level.lower()}_words_part{part_num}.json")
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    print(f"  >>> Saved: {level.lower()}_words_part{part_num}.json ({len(words)} words)")
    return len(words)

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    total = 0
    BATCH = 20  # 20개씩 요청 (더 안정적)
    
    for level, cfg in LEVELS.items():
        print(f"\n{'='*50}\n{level}: {cfg['count']} words (ID {cfg['start']}-{cfg['start']+cfg['count']-1})\n{'='*50}")
        
        current_id, part_num, buffer = cfg["start"], 1, []
        remaining = cfg["count"]
        cats = CATEGORIES[level]
        
        while remaining > 0:
            cat = cats[(cfg["count"] - remaining) // BATCH % len(cats)]
            batch = min(BATCH, remaining)
            
            print(f"\n[{level}] {cat} | ID {current_id}-{current_id+batch-1}")
            words = generate_words(level, cat, batch, current_id)
            
            if words:
                for j, w in enumerate(words):
                    w["id"], w["level"] = current_id + j, level
                buffer.extend(words)
                current_id += len(words)
                remaining -= len(words)
                
                while len(buffer) >= 50:
                    total += save_words(buffer[:50], level, part_num)
                    buffer = buffer[50:]
                    part_num += 1
                    print(f"  Total: {total}/5000")
            
            time.sleep(0.5)
        
        if buffer:
            total += save_words(buffer, level, part_num)
    
    print(f"\n{'='*50}\nCOMPLETE! {total} words\n{'='*50}")

if __name__ == "__main__":
    main()
