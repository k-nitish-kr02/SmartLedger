// This file is deprecated. Use ApiService instead.
// Keeping for backward compatibility if needed.
import ApiService from './ApiService';

class LoginService {
    constructor() {}

    async isLoggedIn(){
        return await ApiService.isLoggedIn();
    }
}

export default LoginService;