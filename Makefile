build-ApiFunction:
	# 只负责把“本机/脚本已生成的产物”拷到 artifacts（SAM 容器里不再 install）
	test -d dist

	mkdir -p "$(ARTIFACTS_DIR)"

	# 1) 只拷运行代码（最关键）
	cp -R dist "$(ARTIFACTS_DIR)/"

	# 2) 可选：如果你代码里有读取 prisma/schema.prisma、或想把 prisma 目录也带上（一般不需要）
	#    不需要就注释/删掉这一行
	cp -R prisma "$(ARTIFACTS_DIR)/" || true

	# 3) 可选：某些项目会在运行时读 package.json（一般不需要）
	#    不需要就注释/删掉这一行
	cp package.json "$(ARTIFACTS_DIR)/" || true

	# ❌ 关键：不要再把 node_modules 打进 Function 包
	# cp -R node_modules "$(ARTIFACTS_DIR)/"
