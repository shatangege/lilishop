package cn.lili.controller.common;

import cn.lili.common.enums.ResultUtil;
import cn.lili.common.vo.ResultMessage;
import cn.lili.modules.system.entity.enums.SettingEnum;
import cn.lili.modules.system.service.SettingService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashSet;
import java.util.Set;

/**
 * 站点基础配置获取
 *
 * @author liushuai(liushuai711 @ gmail.com)
 * @version v4.0
 * @Description:
 * @since 2022/9/22 17:49
 */
@Slf4j
@RestController
@RequestMapping("/common/common/site")
@Api(tags = "站点基础接口")
public class SiteController {

    @Autowired
    private SettingService settingService;

    @ApiOperation(value = "获取站点基础信息")
    @GetMapping
    public ResultMessage<Object> baseSetting() {
        return ResultUtil.data(settingService.get(SettingEnum.BASE_SETTING.name()));
    }
    public static class Solution {
        public static boolean containsDuplicate(int[] nums) {
            Set<Integer> data = new HashSet<Integer>();
            for(int i=0;i < nums.length;i++){
                if(data.contains(nums[i])){
                    return true;
                }
                data.add(nums[i]);
            }
            return false;
        }
    }
    public static void main(String[] args) {
        int[] a = new int[]{1,2,3,1};
        boolean data = Solution.containsDuplicate(a);
        System.out.println(data);
    }
}
