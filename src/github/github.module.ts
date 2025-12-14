import { Module } from "@nestjs/common";
import { HttpModule } from "@nestjs/axios";
import { GithubService } from "./github.service";
import { GithubController } from "./github.controller";

@Module({
  imports: [HttpModule],
  controllers: [GithubController],
  providers: [GithubService],
})
export class GithubModule {}
