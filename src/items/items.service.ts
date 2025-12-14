import { Injectable } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";
import { CreateItemDto } from "./dto/create-item.dto";

@Injectable()
export class ItemsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateItemDto) {
    return this.prisma.item.create({
      data: {
        title: dto.title,
        content: dto.content,
      },
      select: {
        id: true,
        title: true,
        content: true,
        createdAt: true,
      },
    });
  }

  async findAll() {
    return this.prisma.item.findMany({
      orderBy: { createdAt: "desc" },
      select: {
        id: true,
        title: true,
        content: true,
        createdAt: true,
      },
    });
  }

  async remove(id: string) {
    return this.prisma.item.delete({
      where: { id },
      select: {
        id: true,
      },
    });
  }
}
