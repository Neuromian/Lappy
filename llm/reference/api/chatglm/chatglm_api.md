GLM-4 系列提供了复杂推理、超长上下文、极快推理速度等多款模型，适用于多种应用场景。

模型编码：glm-4-plus、glm-4-air、glm-4-air-0111 Preview 、glm-4-airx、glm-4-long 、glm-4-flashx 、glm-4-flash；
大规模处理文本数据，推荐使用 Batch API，一次处理千万级别数据，更有 5 折扣优惠；
查看 产品价格 ；
欢迎在 体验中心 体验；
查看模型 速率限制；
查看您的 API Key；
同步调用
接口请求

类型	说明
方法	https
请求URL	https://open.bigmodel.cn/api/paas/v4/chat/completions
调用方式	同步调用，等待模型完成执行并返回最终结果或使用SSE调用
字符编码	UTF-8
请求格式	JSON
响应格式	JSON或标准Stream Event
请求类型	POST
开发语言	任何能够发起HTTP请求的开发语言
请求参数
参数名称	类型	必填	参数描述
model	String	是	要调用的模型编码。
messages	List<Object>	是	调用语言模型时，当前对话消息列表作为模型的提示输入，以JSON数组形式提供，例如{"role": "user", "content": "Hello"}。可能的消息类型包括系统消息、用户消息、助手消息和工具消息。
request_id	String	否	由用户端传递，需要唯一；用于区分每次请求的唯一标识符。如果用户端未提供，平台将默认生成。
do_sample	Boolean	否	当do_sample为true时，启用采样策略；当do_sample为false时，温度和top_p等采样策略参数将不生效，模型输出随机性会大幅度降低。默认值为true。
stream	Boolean	否	该参数在使用同步调用时应设置为false或省略。表示模型在生成所有内容后一次性返回所有内容。默认值为false。如果设置为true，模型将通过标准Event Stream逐块返回生成的内容。当Event Stream结束时，将返回一个data: [DONE]消息。
temperature	Float	否	采样温度，控制输出的随机性，必须为正数 取值范围是：[0.0,1.0]， 默认值为 0.95，值越大，会使输出更随机，更具创造性；值越小，输出会更加稳定或确定 建议您根据应用场景调整 top_p 或 temperature 参数，但不要同时调整两个参数
top_p	Float	否	用温度取样的另一种方法，称为核取样 取值范围是：[0.0, 1.0]，默认值为 0.70 模型考虑具有 top_p 概率质量 tokens 的结果 例如：0.10 意味着模型解码器只考虑从前 10% 的概率的候选集中取 tokens 建议您根据应用场景调整 top_p 或 temperature 参数，但不要同时调整两个参数
max_tokens	Integer	否	控制生成的响应的最大 token 数量，
默认值：动态计算（默认情况下，max_tokens的值会根据上下文长度减去输入长度来自动计算）
最大值： max_tokens 最大支持4095，设置为超过 4095，则会被自动限制为 4095。
response_format	Object	否	指定模型输出格式，默认为 text,
{ "type": "text" }：文本输出模式，模型返回普通的文本输出。
{ "type": "json_object" }：JSON输出模式，模型返回有效的 JSON 输出。
Beta 版本采用工程实现方式，实现细节请参考说明文档 。
stop	List	否	模型遇到stop指定的字符时会停止生成。目前仅支持单个stop词，格式为["stop_word1"]。
tools	List	否	模型可以调用的工具。
  type	String	是	工具类型，目前支持 function、retrieval、web_search。

function: `Object` (必需): 仅当工具类型为 function 时补充。
 name: `String` (必需): 函数名称，只能包含 a-z、A-Z、0-9、下划线和连字符。最大长度限制为64。
 description: `String` (必需): 用于描述函数的能力。模型将根据此描述确定函数调用的方式。
 parameters: `Object` (必需): 参数字段必须传递一个Json Schema对象，以准确定义函数接受的参数。如果调用函数时不需要参数，则可以省略此参数。
"parameters": {
  "type": "object",
  "properties": { "location": { 
    "type": "string",
    "description": "城市，例如：北京" 
  }, 
  "unit": { "type": "string", "enum": ["celsius", "fahrenheit"] }
},
"required": ["location"]
}
建议在使用 FunctionCall 时关闭 `do_sample`，或将 `temperature` 和 `top_p` 调整为较低值，以提供成功率。
更多详情：函数调用使用指南

retrieval: `Object`
描述: 仅当工具类型为 retrieval 时补充。
 knowledge_id: `String` (必需): 涉及知识库ID时，请前往开放平台的知识库模块创建或获取。
 prompt_template: `String` (非必需): 请求模型时的知识库模板，默认模板：
 ```从文档 "{{ knowledge }}" 中查找问题的答案 "{{question}}" 如果找到答案，仅使用文档的陈述来回答问题；如果未找到，则使用自己的知识回答，并告知用户此信息不是来自文档。不要重复问题，直接开始回答。```
用户自定义模板时，知识库内容占位符和用户端问题占位符必须分别为{{ knowledge }}和{{ question }};
更多详情：Retrieval使用指南

web_search: `Object`
描述: 仅当工具类型为 web_search 时补充，如果tools中存在type retrieval，则web_search将不生效。
 enable: `Boolean` (非必需): 网络搜索功能：默认为关闭状态（False）。启用搜索：设置为 `True`。禁用搜索：设置为 `False`。
 search_query: `String` (非必需): 强制自定义搜索键内容。
 search_result: `Boolean` (非必需): 获取网页搜索来源的详细信息。默认禁用。启用：true，禁用：false。
更多详情：web_search使用指南

tool_choice	String或Object	否	用于控制模型选择调用哪个函数的方式，仅在工具类型为function时补充。默认auto，目前仅支持auto。
user_id	String	否	终端用户的唯一ID，帮助平台对终端用户的非法活动、生成非法不当信息或其他滥用行为进行干预。ID长度要求：至少6个字符，最多128个字符。
message 格式
System Message 格式

参数名称	类型	必填	参数说明
role	String	是	消息的角色信息，此时应为system
content	String	是	消息内容
User Message Format

参数名称	类型	必填	参数说明
role	String	是	消息的角色信息，此时应为user
content	String	是	消息内容
Assistant Message Format

参数名称	类型	必填	参数说明
role	String	是	消息的角色信息，此时应为assistant
content	String	是	"content"与"tool_calls"二必选一。
消息内容。其中包括了tool_calls字段，content字段为空。
tool_calls	List	是	"content"与"tool_calls"二必选一。
模型产生的工具调用消息
 id	String	是	工具id
 type	String	是	工具类型, 支持web_search、retrieval、function
 function	Object	否	type为"function"时不为空
  name	String	是	函数名称
  arguments	String	是	模型生成的调用函数的参数列表，JSON 格式。请注意，模型可能会生成无效的JSON，也可能会虚构一些不在您的函数规范中的参数。在调用函数之前，请在代码中验证这些参数是否有效。
Tool Message格式

Tool Message表示调用工具后的返回结果。模型然后根据工具消息输出自然语言格式的消息给用户。

参数名称	类型	必填	参数描述
role	String	是	消息的角色信息，此时应为tool。
content	String	是	工具消息的内容，调用工具后的返回结果。
tool_call_id	String	是	工具调用的记录。
响应参数
参数名称	类型	参数描述
id	String	任务ID
created	Long	请求创建时间，为Unix时间戳，单位为秒
model	String	模型名称
choices	List	当前对话的模型输出内容
 index	Integer	结果索引
 finish_reason	String	模型推理终止的原因。可以是’stop’、‘tool_calls’、‘length’、‘sensitive’或’network_error’。
  message	Object	模型返回的文本消息
  role	String	当前对话角色，默认为’assistant’（模型）
  content	String	当前对话内容。命中函数时为null，否则返回模型推理结果。
 tool_calls	List<Object>	模型生成的应调用的函数名称和参数。
  function	Object	包含模型生成的函数名称和JSON格式的参数。
   name	String	模型生成的函数名称。
   arguments	String	模型生成的函数调用参数的JSON格式。调用函数前请验证参数。
  id	String	命中函数的唯一标识符。
  type	String	模型调用的工具类型，目前仅支持’function’。
usage	Object	模型调用结束时返回的token使用统计。
 prompt_tokens	Integer	用户输入的token数量
 completion_tokens	Integer	模型输出的token数量
 total_tokens	Integer	总token数量
web_search	List	返回与网页搜索相关的信息。
 icon	String	来源网站的图标
 title	String	搜索结果的标题
 link	String	搜索结果的网页链接
 media	String	搜索结果网页的媒体来源名称
 content	String	搜索结果网页引用的文本内容
请求示例
from zhipuai import ZhipuAI
client = ZhipuAI(api_key="")  # 请填写您自己的APIKey
response = client.chat.completions.create(
    model="glm-4-plus",  # 请填写您要调用的模型名称
    messages=[
        {"role": "user", "content": "作为一名营销专家，请为我的产品创作一个吸引人的口号"},
        {"role": "assistant", "content": "当然，要创作一个吸引人的口号，请告诉我一些关于您产品的信息"},
        {"role": "user", "content": "智谱AI开放平台"},
        {"role": "assistant", "content": "点燃未来，智谱AI绘制无限，让创新触手可及！"},
        {"role": "user", "content": "创作一个更精准且吸引人的口号"}
    ],
)
print(response.choices[0].message)

响应示例
{
  "created": 1703487403,
  "id": "8239375684858666781",
  "model": "glm-4-plus",
  "request_id": "8239375684858666781",
  "choices": [
      {
          "finish_reason": "stop",
          "index": 0,
          "message": {
              "content": "以AI绘蓝图 — 智谱AI，让创新的每一刻成为可能。",
              "role": "assistant"
          }
      }
  ],
  "usage": {
      "completion_tokens": 217,
      "prompt_tokens": 31,
      "total_tokens": 248
  }
}

流式输出
响应参数
参数名称	类型	参数描述
id	String	智谱AI开放平台生成的任务序号，调用请求结果接口时请使用此序号
created	Long	请求创建时间，为Unix时间戳，单位为秒
choices	List	当前对话的模型输出内容
 index	Integer	结果索引
 finish_reason	String	模型推理终止的原因。'stop’表示自然结束或触发stop词，'tool_calls’表示模型命中函数，'length’表示达到token长度限制，'sensitive’表示内容被安全审核接口拦截（用户应判断并决定是否撤回公开内容），'network_error’表示模型推理异常。
 delta	Object	模型增量返回的文本信息
 role	String	当前对话角色，默认为’assistant’（模型）
 content	String	当前对话内容。命中函数时为null，否则返回模型推理结果。
 tool_calls	List	模型生成的应调用的函数名称和参数。
  function	Object	包含模型生成的函数名称和JSON格式的参数。
   name	String	模型生成的函数名称。
   arguments	String	模型生成的函数调用参数的JSON格式。调用函数前请验证参数。
  id	String	命中函数的唯一标识符。
  type	String	模型调用的工具类型，目前仅支持’function’。
usage	Object	模型调用结束时返回的token使用统计。
 prompt_tokens	Integer	用户输入的token数量
 completion_tokens  	Integer	模型输出的token数量
 total_tokens	Integer	总token数量
web_search	List	返回与网页搜索相关的信息。icon
 icon	String	来源网站的图标
 title	String	搜索结果的标题
 link	String	搜索结果的网页链接
 media	String	搜索结果网页的媒体来源名称
 content	String	搜索结果网页引用的文本内容
请求示例
最新的模型GLM-4系列模型支持系统提示、函数调用、检索、Web_Search等新功能。要使用这些新功能，需要升级到最新版本的Python SDK。如果您安装了旧版本的SDK，请更新到最新版本。

pip install --upgrade zhipuai
from zhipuai import ZhipuAI
client = ZhipuAI(api_key="")  # 请填写您自己的APIKey
response = client.chat.completions.create(
    model="glm-4-plus",  # 请填写您要调用的模型名称
    messages=[
        {"role": "system", "content": "你是一个乐于回答各种问题的小助手，你的任务是提供专业、准确、有洞察力的建议。"},
        {"role": "user", "content": "我对太阳系的行星非常感兴趣，尤其是土星。请提供关于土星的基本信息，包括它的大小、组成、环系统以及任何独特的天文现象。"},
    ],
    stream=True,
)
for chunk in response:
    print(chunk.choices[0].delta)

响应示例
data: {"id":"8313807536837492492","created":1706092316,"model":"glm-4-plus","choices":[{"index":0,"delta":{"role":"assistant","content":"土"}}]}
data: {"id":"8313807536837492492","created":1706092316,"model":"glm-4-plus","choices":[{"index":0,"delta":{"role":"assistant","content":"星"}}]}
....
data: {"id":"8313807536837492492","created":1706092316,"model":"glm-4-plus","choices":[{"index":0,"delta":{"role":"assistant","content":"，"}}]}
data: {"id":"8313807536837492492","created":1706092316,"model":"glm-4-plus","choices":[{"index":0,"delta":{"role":"assistant","content":"主要由"}}]}
data: {"id":"8313807536837492492","created":1706092316,"model":"glm-4-plus","choices":[{"index":0,"finish_reason":"length","delta":{"role":"assistant","content":""}}],"usage":{"prompt_tokens":60,"completion_tokens":100,"total_tokens":160}}
data: [DONE]

