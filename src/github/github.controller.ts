import { Controller, Get, Headers } from "@nestjs/common";
import { GithubService } from "./github.service";

@Controller("github")
export class GithubController {
  constructor(private readonly github: GithubService) {}

  @Get("me")
  async me(
    @Headers("authorization") authorization?: string,
    @Headers("x-github-token") xGithubToken?: string,
  ) {
    // 允许两种传法：
    // 1) Authorization: Bearer <token>
    // 2) x-github-token: <token>
    const token =
      xGithubToken?.trim() ??
      authorization?.replace(/^Bearer\s+/i, "").trim() ??
      "";

    return this.github.getMe(token);
  }
}
