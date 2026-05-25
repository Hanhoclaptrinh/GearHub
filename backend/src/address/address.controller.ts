import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { AddressService } from './address.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';

@Controller('address')
@UseGuards(JwtAuthGuard)
export class AddressController {
    constructor(private readonly addressService: AddressService) { }

    @Post()
    create(@Req() req, @Body() createAddressDto: CreateAddressDto) {
        return this.addressService.createAddress(req.user.userId, createAddressDto);
    }

    @Get()
    findAll(@Req() req) {
        return this.addressService.findAllAddresses(req.user.userId);
    }

    @Get(':id')
    findOne(@Req() req, @Param('id') id: string) {
        return this.addressService.findOneAddress(req.user.userId, id);
    }

    @Patch(':id')
    update(@Req() req, @Param('id') id: string, @Body() updateAddressDto: UpdateAddressDto) {
        return this.addressService.updateAddress(req.user.userId, id, updateAddressDto);
    }

    @Delete(':id')
    remove(@Req() req, @Param('id') id: string) {
        return this.addressService.removeAddress(req.user.userId, id);
    }

    @Patch(':id/default')
    setDefault(@Req() req, @Param('id') id: string) {
        return this.addressService.setDefaultAddress(req.user.userId, id);
    }
}
