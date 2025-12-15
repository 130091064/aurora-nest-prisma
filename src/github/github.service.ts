import { Injectable, UnauthorizedException } from "@nestjs/common";
import { HttpService } from "@nestjs/axios";
import { firstValueFrom } from "rxjs";

@Injectable()
export class GithubService {
  constructor(private readonly http: HttpService) {}

  async getMe(token: string) {
    if (!token) throw new UnauthorizedException("Missing GitHub token");

    // GitHub 推荐 Header：Authorization + Accept + X-GitHub-Api-Version
    const res = await firstValueFrom(
      this.http.get("https://api.github.com/user", {
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
          "User-Agent": "aurora-nest-prisma", // 有些情况下必须带
        },
        proxy: false, // 禁用 axios 代理
      }),
    );

    // 返回你作业需要的关键字段（避免把全部信息透出）
    const u = res.data;
    return {
      id: u.id,
      login: u.login,
      name: u.name,
      avatar_url: u.avatar_url,
      html_url: u.html_url,
      email: u.email,
      public_repos: u.public_repos,
      followers: u.followers,
      following: u.following,
      created_at: u.created_at,
    };
  }
}
