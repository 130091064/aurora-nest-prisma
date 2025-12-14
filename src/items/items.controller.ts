import { Body, Controller, Delete, Get, Param, Post } from "@nestjs/common";
import { CreateItemDto } from "./dto/create-item.dto";
import { ItemsService } from "./items.service";

@Controller("items")
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Post()
  create(@Body() dto: CreateItemDto) {
    return this.itemsService.create(dto);
  }

  @Get()
  findAll() {
    return this.itemsService.findAll();
  }

  @Delete(":id")
  remove(@Param("id") id: string) {
    return this.itemsService.remove(id);
  }
}
